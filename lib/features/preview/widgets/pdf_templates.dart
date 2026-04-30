import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../../../core/utils/resume_translations.dart';
import '../../../core/utils/startup_profile_sections.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../templates/ats_friendly_modern_template_support.dart';
import '../../templates/ats_optimized_clean_template_support.dart';
import '../../templates/ats_standard_format_template_support.dart';
import '../../templates/balanced_two_column_template_support.dart';
import '../../templates/bluewave_tech_template_support.dart';
import '../../templates/classic_ats_template_support.dart';
import '../../templates/corporate_template_support.dart';
import '../../templates/corporate_navy_template_support.dart';
import '../../templates/creative_professional_template_support.dart';
import '../../templates/designer_profile_template_support.dart';
import '../../templates/elegant_gold_layout_template_support.dart';
import '../../templates/elegant_design_template_support.dart';
import '../../templates/entry_level_template_support.dart';
import '../../templates/classic_temp_template_support.dart';
import '../../templates/executive_classic_template_support.dart';
import '../../templates/flexcolor_sidebar_template_support.dart';
import '../../templates/forest_edge_classic_template_support.dart';
import '../../templates/forest_edge_template_support.dart';
import '../../templates/graphite_column_template_support.dart';
import '../../templates/healthcare_resume_template_support.dart';
import '../../templates/infographic_template_support.dart';
import '../../templates/minimal_clean_template_support.dart';
import '../../templates/minimal_clean_ats_template_support.dart';
import '../../templates/modern_edge_template_support.dart';
import '../../templates/mono_nova_template_support.dart';
import '../../templates/editorial_frame_template_support.dart';
import '../../templates/professional_accountant_template_support.dart';
import '../../templates/professional_template_support.dart';
import '../../templates/rosewood_panel_template_support.dart';
import '../../templates/slate_arc_template_support.dart';
import '../../templates/vertical_timeline_template_support.dart';

part 'templates/modern_nova_pdf_template.dart';
part 'templates/ats_friendly_modern_resume_pdf_template.dart';
part 'templates/ats_optimized_clean_resume_pdf_template.dart';
part 'templates/ats_standard_format_resume_pdf_template.dart';
part 'templates/balanced_two_column_layout_pdf_template.dart';
part 'templates/bluewave_tech_resume_pdf_template.dart';
part 'templates/classic_ats_resume_pdf_template.dart';
part 'templates/classic_resume_pdf_template.dart';
part 'templates/creative_resume_pdf_template.dart';
part 'templates/creative_professional_resume_pdf_template.dart';
part 'templates/developer_resume_pdf_template.dart';
part 'templates/designer_profile_resume_pdf_template.dart';
part 'templates/academic_resume_pdf_template.dart';
part 'templates/education_resume_pdf_template.dart';
part 'templates/elegant_gold_layout_pdf_template.dart';
part 'templates/elegant_design_resume_pdf_template.dart';
part 'templates/elite_resume_pdf_template.dart';
part 'templates/emerald_executive_resume_pdf_template.dart';
part 'templates/entry_level_resume_pdf_template.dart';
part 'templates/executive_classic_resume_pdf_template.dart';
part 'templates/infographic_resume_pdf_template.dart';
part 'templates/editorial_frame_resume_pdf_template.dart';
part 'templates/slate_arc_resume_pdf_template.dart';
part 'templates/one_page_resume_pdf_template.dart';
part 'templates/professional_accountant_resume_pdf_template.dart';
part 'templates/classic_temp_resume_pdf_template.dart';
part 'templates/business_management_resume_pdf_template.dart';
part 'templates/minimal_resume_pdf_template.dart';
part 'templates/minimal_clean_resume_pdf_template.dart';
part 'templates/minimal_clean_ats_resume_pdf_template.dart';
part 'templates/multicolor_resume_pdf_template.dart';
part 'templates/flexcolor_sidebar_pdf_template.dart';
part 'templates/forest_edge_classic_resume_pdf_template.dart';
part 'templates/forest_edge_resume_pdf_template.dart';
part 'templates/graphite_column_resume_pdf_template.dart';
part 'templates/healthcare_resume_pdf_template.dart';
part 'templates/modern_edge_resume_pdf_template.dart';
part 'templates/pink_rose_modern_pdf_template.dart';
part 'templates/professional_resume_pdf_template.dart';
part 'templates/rosewood_panel_resume_pdf_template.dart';
part 'templates/sales_and_marketing_resume_pdf_template.dart';
part 'templates/two_column_resume_pdf_template.dart';
part 'templates/vividpro_resume_pdf_template.dart';
part 'templates/classic_plus_resume_pdf_template.dart';
part 'templates/corporate_resume_pdf_template.dart';
part 'templates/corporate_navy_resume_pdf_template.dart';
part 'templates/mono_nova_resume_pdf_template.dart';
part 'templates/vertical_timeline_pdf_template.dart';

// -- PDF translation helpers ---------------------------------------------------
String _pdfLang = 'English';
String _h(String text) => ResumeTranslations.translate(text, _pdfLang);
String _present() => ResumeTranslations.present(_pdfLang);
String _pdfDate(DateTime date, {String pattern = 'MMM yyyy'}) =>
  DateFormat(pattern).format(date);

// -- Font loading --------------------------------------------------------------
const _nonLatinLanguages = {
  'Arabic',
  'Mandarin Chinese',
  'Japanese',
  'Korean',
  'Hindi',
  'Russian',
  'Ukrainian',
  'Greek',
};

bool _isNonLatinLang() => _nonLatinLanguages.contains(_pdfLang);

String _pdfFontFamily = 'Roboto';

pw.Font? _unicodeFont;
pw.Font? _unicodeFontBold;
String _unicodeFontLang = '';

pw.Font? _customFont;
pw.Font? _customFontBold;
String _customFontName = '';

Future<void> _loadUnicodeFontIfNeeded() async {
  if (!_isNonLatinLang()) {
    _unicodeFont = null;
    _unicodeFontBold = null;
    _unicodeFontLang = '';
    return;
  }

  if (_unicodeFontLang == _pdfLang && _unicodeFont != null) {
    return;
  }

  try {
    switch (_pdfLang) {
      case 'Hindi':
        _unicodeFont = await PdfGoogleFonts.notoSansDevanagariRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansDevanagariBold();
        break;
      case 'Arabic':
        _unicodeFont = await PdfGoogleFonts.notoSansArabicRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansArabicBold();
        break;
      case 'Mandarin Chinese':
        _unicodeFont = await PdfGoogleFonts.notoSansSCRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansSCBold();
        break;
      case 'Japanese':
        _unicodeFont = await PdfGoogleFonts.notoSansJPRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansJPSemiBold();
        break;
      case 'Korean':
        _unicodeFont = await PdfGoogleFonts.notoSansKRRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansKRBold();
        break;
      default:
        _unicodeFont = await PdfGoogleFonts.notoSansRegular();
        _unicodeFontBold = await PdfGoogleFonts.notoSansBold();
        break;
    }
    _unicodeFontLang = _pdfLang;
  } catch (_) {
    _unicodeFont = null;
    _unicodeFontBold = null;
    _unicodeFontLang = '';
  }
}

Future<void> _loadCustomFontIfNeeded() async {
  if (_isNonLatinLang()) {
    _customFont = null;
    _customFontBold = null;
    _customFontName = '';
    return;
  }

  if (_customFontName == _pdfFontFamily && _customFont != null) {
    return;
  }

  try {
    switch (_pdfFontFamily) {
      case 'Open Sans':
        _customFont = await PdfGoogleFonts.openSansRegular();
        _customFontBold = await PdfGoogleFonts.openSansBold();
        break;
      case 'Lato':
        _customFont = await PdfGoogleFonts.latoRegular();
        _customFontBold = await PdfGoogleFonts.latoBold();
        break;
      case 'Montserrat':
        _customFont = await PdfGoogleFonts.montserratRegular();
        _customFontBold = await PdfGoogleFonts.montserratBold();
        break;
      case 'Playfair Display':
        _customFont = await PdfGoogleFonts.playfairDisplayRegular();
        _customFontBold = await PdfGoogleFonts.playfairDisplayBold();
        break;
      case 'Merriweather':
        _customFont = await PdfGoogleFonts.merriweatherRegular();
        _customFontBold = await PdfGoogleFonts.merriweatherBold();
        break;
      case 'Raleway':
        _customFont = await PdfGoogleFonts.ralewayRegular();
        _customFontBold = await PdfGoogleFonts.ralewayBold();
        break;
      case 'Poppins':
        _customFont = await PdfGoogleFonts.poppinsRegular();
        _customFontBold = await PdfGoogleFonts.poppinsBold();
        break;
      case 'Roboto':
      default:
        _customFont = await PdfGoogleFonts.robotoRegular();
        _customFontBold = await PdfGoogleFonts.robotoBold();
        break;
    }
    _customFontName = _pdfFontFamily;
  } catch (_) {
    _customFont = null;
    _customFontBold = null;
    _customFontName = '';
  }
}

Future<void> initPdfSettings(ResumeModel resume) async {
  _pdfLang = resume.writingLanguage;
  _pdfFontFamily = resume.fontFamily;
  await _loadUnicodeFontIfNeeded();
  await _loadCustomFontIfNeeded();
}

pw.Font _resolvedBaseFont() {
  if (_unicodeFont != null) {
    return _unicodeFont!;
  }
  return _customFont ?? pw.Font.helvetica();
}

pw.Font _resolvedBoldFont() {
  if (_unicodeFontBold != null) {
    return _unicodeFontBold!;
  }
  return _customFontBold ?? pw.Font.helveticaBold();
}

pw.Document _buildDocument() {
  return pw.Document(
    theme: pw.ThemeData.withFont(
      base: _resolvedBaseFont(),
      bold: _resolvedBoldFont(),
      italic: _resolvedBaseFont(),
      boldItalic: _resolvedBoldFont(),
    ),
  );
}

String _sanitizePdfText(String? text) {
  final raw = text ?? '';
  final bulletPattern = RegExp(
    '[\u2022\u2023\u2043\u2219\u25A0\u25AA\u25AB\u25B4\u25B8\u25BA'
    '\u25CB\u25CF\u25E6\u2605\u2606\u2713\u2714\u2717\u2718'
    '\u27A2\u2794\u2799\u279B\u00B7\u2027\u26AB\u26AA\u2981]',
  );
  final sanitized = raw
      .replaceAll(bulletPattern, '-')
      .replaceAll('ΓÇó', '-')
      .replaceAll('•', '-')
      .trimRight();

  if (_unicodeFont != null) {
    return sanitized;
  }

  return sanitized.replaceAll(RegExp(r'[^\x00-\xFF]'), '');
}

List<pw.Widget> _buildSummaryBullets(
  String text,
  PdfColor accentColor, {
  pw.TextAlign textAlign = pw.TextAlign.left,
}) {
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

  if (segments.isEmpty) {
    return const [];
  }

  return segments.map((line) {
    final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 12,
            child: pw.CustomPaint(
              size: const PdfPoint(12, 12),
              painter: (canvas, size) {
                canvas.setFillColor(accentColor);
                canvas.drawEllipse(6, 6, 2.5, 2.5);
                canvas.fillPath();
              },
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              cleanLine,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.6),
              textAlign: textAlign,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

pw.Widget _buildRightBarSectionHeader(
  String title, {
  required PdfColor textColor,
  required PdfColor dividerColor,
  PdfColor? barColor,
  double fontSize = 11,
  double letterSpacing = 0.7,
  double marginBottom = 6,
  double titleBottomSpacing = 3,
  double lineThickness = 1,
  double barWidth = 2.6,
  double barHeight = 10,
}) {
  return pw.Container(
    width: double.infinity,
    margin: pw.EdgeInsets.only(bottom: marginBottom),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.only(right: barWidth + 8),
          child: pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
              letterSpacing: letterSpacing,
            ),
          ),
        ),
        pw.SizedBox(height: titleBottomSpacing),
        pw.Container(
          height: barHeight,
          child: pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  height: lineThickness,
                  color: dividerColor,
                ),
              ),
              pw.Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  width: barWidth,
                  color: barColor ?? textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

const _builtInSectionKeys = <String>[
  'summary',
  'experience',
  'education',
  'skills',
  'projects',
  'certifications',
  'languages',
];

List<String> _defaultPdfSectionOrder(String templateId) {
  switch (templateId) {
    case 'developer':
      return [
        'skills',
        'experience',
        'projects',
        'education',
        'certifications',
        'languages',
        'summary',
      ];
    case 'academic':
      return [
        'summary',
        'education',
        'skills',
        'experience',
        'projects',
        'certifications',
        'languages',
      ];
    case 'startup':
      return [
        'summary',
        'skills',
        'experience',
        'projects',
        'education',
        'certifications',
        'languages',
      ];
    case 'modern_aesthetic':
    case 'classic2':
    case 'modern_resume':
    case 'classic_temp':
      return [
        'summary',
        'experience',
        'education',
        'skills',
        'projects',
        'certifications',
        'languages',
      ];
    case 'education_resume':
      return [
        'education',
        'experience',
        'summary',
        'skills',
        'projects',
        'certifications',
        'languages',
      ];
    case 'blue_gray':
      return [
        'summary',
        'experience',
        'skills',
        'projects',
        'certifications',
        'education',
        'languages',
      ];
    case 'sales':
      return [
        'summary',
        'experience',
        'education',
        'skills',
        'projects',
        'certifications',
        'languages',
      ];
    case 'executive':
      return [
        'summary',
        'experience',
        'certifications',
        'skills',
        'projects',
        'education',
        'languages',
      ];
    case 'designer_profile':
      return [
        'summary',
        'projects',
        'experience',
        'skills',
        'certifications',
        'education',
        'languages',
      ];
    case 'professional_tone':
      return [
        'summary',
        'experience',
        'certifications',
        'skills',
        'education',
        'projects',
        'languages',
      ];
    case 'elegant_gold_layout':
      return [
        'summary',
        'experience',
        'certifications',
        'skills',
        'projects',
        'education',
        'languages',
      ];
    default:
      return List<String>.from(_builtInSectionKeys);
  }
}

Future<List<String>> _loadPdfSectionOrder(ResumeModel resume) async {
  return _loadPdfSectionOrderForKeys(
    resume,
    defaultOrder: _defaultPdfSectionOrder(resume.templateId),
    allowedKeys: _builtInSectionKeys,
  );
}

Future<List<String>> _loadPdfSectionOrderForKeys(
  ResumeModel resume, {
  required List<String> defaultOrder,
  required Iterable<String> allowedKeys,
}) async {
  final prefs = StorageService.prefs;
  final saved = prefs.getString('section_order_${resume.id}');
  final allowed = {
    ...allowedKeys,
    ...resume.customSections.map((section) => section.id),
  };
  final baseOrder = defaultOrder.where(allowed.contains).toList();

  if (saved == null || saved.trim().isEmpty) {
    return baseOrder;
  }

  final loaded = saved
      .split(',')
      .map((key) => key.trim())
      .where(allowed.contains)
      .toList();
  final missing = baseOrder.where((key) => !loaded.contains(key));
  final extras = allowed.where(
    (key) => !loaded.contains(key) && !baseOrder.contains(key),
  );
  return [...loaded, ...missing, ...extras];
}

List<pw.Widget> _applyPdfSectionOrder(
  List<String> orderedKeys,
  Map<String, List<pw.Widget>> sectionWidgets,
) {
  final widgets = <pw.Widget>[];
  final mergedKeys = [
    ...orderedKeys,
    ...sectionWidgets.keys.where((key) => !orderedKeys.contains(key)),
  ];

  for (final key in mergedKeys) {
    final section = sectionWidgets[key];
    if (section != null && section.isNotEmpty) {
      widgets.addAll(section);
    }
  }

  return widgets;
}

void _addUserCustomSections({
  required ResumeModel resume,
  required Map<String, List<pw.Widget>> sections,
  required PdfColor accentColor,
  double bottomSpacing = 8,
  pw.Widget Function(String title)? headerBuilder,
  pw.Widget Function(List<pw.Widget> children)? sectionWrapper,
}) {
  for (final section in orderedUserCustomSections(resume)) {
    final sectionWidgets = _buildGenericUserCustomSectionWidgets(
      section,
      accentColor: accentColor,
      bottomSpacing: bottomSpacing,
      headerBuilder: headerBuilder,
    );
    if (sectionWrapper != null) {
      sections[section.id] = [
        sectionWrapper(sectionWidgets),
      ];
    } else {
      sections[section.id] = sectionWidgets;
    }
  }
}

List<pw.Widget> _buildGenericUserCustomSectionWidgets(
  CustomSection section, {
  required PdfColor accentColor,
  double bottomSpacing = 8,
  pw.Widget Function(String title)? headerBuilder,
}) {
  final normalizedTitle = normalizeUserCustomSectionTitle(section.title);
  final title = normalizedTitle.isEmpty ? 'CUSTOM SECTION' : normalizedTitle;
  final itemWidgets = section.items
      .map(
        (item) => _buildGenericUserCustomSectionItem(
          item,
          accentColor: accentColor,
        ),
      )
      .whereType<pw.Widget>()
      .toList(growable: false);

  final headerWidget = headerBuilder?.call(title) ??
      _buildGenericUserCustomSectionHeader(title.toUpperCase(), accentColor);

  if (itemWidgets.isEmpty) {
    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          headerWidget,
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _sanitizePdfText('No content added yet.'),
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey,
              ),
            ),
          ),
          if (bottomSpacing > 0) pw.SizedBox(height: bottomSpacing),
        ],
      ),
    ];
  }

  final sectionWidgets = <pw.Widget>[
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          headerWidget,
          itemWidgets.first,
        ],
      ),
    ),
    ...itemWidgets.skip(1).map(
          (widget) => pw.Inseparable(child: widget),
        ),
    if (bottomSpacing > 0) pw.SizedBox(height: bottomSpacing),
  ];

  return sectionWidgets;
}

pw.Widget _buildGenericUserCustomSectionHeader(
  String title,
  PdfColor accentColor,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(title),
          style: pw.TextStyle(
            fontSize: 10.4,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF111827),
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: 42,
          height: 2,
          color: _scalePdfColor(accentColor, 1.0, 0.82),
        ),
      ],
    ),
  );
}

pw.Widget? _buildGenericUserCustomSectionItem(
  CustomSectionItem item, {
  required PdfColor accentColor,
}) {
  final displayItem = buildUserCustomSectionDisplayItem(item);
  final heading = _sanitizePdfText(displayItem.heading).trim();
  final detailLines = displayItem.detailLines
      .map((line) => _sanitizePdfText(line).trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  final metaParts = <String>[];
  if (displayItem.subtitle.isNotEmpty) {
    metaParts.add(_sanitizePdfText(displayItem.subtitle).trim());
  }
  if (displayItem.date != null) {
    metaParts.add(DateFormat('MMM yyyy').format(displayItem.date!));
  }

  if (!displayItem.hasContent) {
    return null;
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (heading.isNotEmpty)
          pw.Text(
            heading,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF111827),
            ),
          ),
        if (metaParts.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
            child: pw.Text(
              metaParts.join('  |  '),
              style: const pw.TextStyle(
                fontSize: 8.2,
                color: PdfColor.fromInt(0xFF6B7280),
              ),
            ),
          ),
        ...detailLines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4.5,
                  height: 4.5,
                  margin: const pw.EdgeInsets.only(top: 3.2, right: 6),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(
                      fontSize: 8.9,
                      color: PdfColor.fromInt(0xFF374151),
                      lineSpacing: 1.28,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

List<String> _collectExperienceLines(Experience exp) {
  final lines = <String>[];
  if (exp.achievements.isNotEmpty) {
    lines.addAll(
      exp.achievements
          .map((item) => _sanitizePdfText(item).trim())
          .where((item) => item.isNotEmpty),
    );
  }

  if (exp.description.isNotEmpty) {
    final descriptionLines = _sanitizePdfText(exp.description)
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    for (final line in descriptionLines) {
      if (!lines.contains(line)) {
        lines.add(line);
      }
    }
  }

  return lines;
}

List<String> _splitPdfLines(String? text) {
  final normalized = _sanitizePdfText(text);
  if (normalized.trim().isEmpty) {
    return const [];
  }

  final trimmedLines = normalized
      .split(RegExp(r'\n+'))
      .map(
        (line) => line.replaceFirst(RegExp(r'^[-*•▪■✦]+\s*'), '').trim(),
      )
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  if (trimmedLines.length > 1) {
    return trimmedLines;
  }

  final sentenceLines = normalized
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map(
        (line) => line.replaceFirst(RegExp(r'^[-*•▪■✦]+\s*'), '').trim(),
      )
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  return sentenceLines.isNotEmpty ? sentenceLines : trimmedLines;
}

List<String> _descriptionFirstExperienceLines(Experience exp) {
  final lines = <String>[];

  for (final line in _splitPdfLines(exp.description)) {
    if (!lines.contains(line)) {
      lines.add(line);
    }
  }

  for (final item in exp.achievements
      .map((achievement) => _sanitizePdfText(achievement).trim())
      .where((achievement) => achievement.isNotEmpty)) {
    if (!lines.contains(item)) {
      lines.add(item);
    }
  }

  return lines;
}

List<String> _resumeContactValues(
  ResumeModel resume, {
  bool includeAddress = true,
  bool includeLinkedIn = true,
  bool includeGithub = true,
  bool includeWebsite = true,
}) {
  final values = <String>[];

  void addValue(String? raw) {
    final value = _sanitizePdfText(raw).trim();
    if (value.isNotEmpty && !values.contains(value)) {
      values.add(value);
    }
  }

  addValue(resume.personalInfo.email);
  addValue(resume.personalInfo.phone);
  if (includeAddress) {
    addValue(resume.personalInfo.address);
  }
  if (includeLinkedIn) {
    addValue(resume.personalInfo.linkedIn);
  }
  if (includeGithub) {
    addValue(resume.personalInfo.github);
  }
  if (includeWebsite) {
    addValue(resume.personalInfo.website);
  }

  return values;
}

List<String> _splitStartupSectionText(String? raw) {
  final normalized = _sanitizePdfText(raw);
  if (normalized.trim().isEmpty) {
    return const [];
  }

  return normalized
      .split(RegExp(r'\n+|,+|;+'))
      .map((item) => item.replaceFirst(RegExp(r'^[-*•]+\s*'), '').trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _collectStartupCustomSectionLines(
  ResumeModel resume,
  String sectionId,
) {
  final section = resume.customSections.where((item) => item.id == sectionId);
  if (section.isEmpty) {
    return const [];
  }

  final lines = <String>[];
  for (final item in section.first.items) {
    for (final value in [item.title, item.subtitle, item.description]) {
      for (final part in _splitStartupSectionText(value)) {
        if (!lines.contains(part)) {
          lines.add(part);
        }
      }
    }
  }

  return lines;
}

List<String> _collectStartupToolLines(ResumeModel resume) {
  final skillLines = resume.skills
      .map((skill) => _sanitizePdfText(skill.name).trim())
      .where((skill) => skill.isNotEmpty)
      .toList(growable: false);

  if (skillLines.isNotEmpty) {
    return skillLines;
  }

  return _collectStartupCustomSectionLines(resume, 'startup_tools');
}

List<pw.Widget> _buildExperienceLineWidgets(
  Experience exp,
  PdfColor accentColor, {
  double fontSize = 9,
  double leftPadding = 12,
  PdfColor? textColor,
  PdfColor? bulletColor,
}) {
  final lines = _collectExperienceLines(exp);
  return lines
      .map(
        (line) => pw.Padding(
          padding: pw.EdgeInsets.only(left: leftPadding, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '- ',
                style: pw.TextStyle(
                    fontSize: fontSize, color: bulletColor ?? accentColor),
              ),
              pw.Expanded(
                child: pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    lineSpacing: 1.5,
                    color: textColor,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}

List<pw.Widget> _buildSparkSummaryBullets(
  String text,
  PdfColor accentColor, {
  double fontSize = 9.5,
  double lineSpacing = 1.45,
  double bottomPadding = 5,
  PdfColor? textColor,
  pw.TextAlign textAlign = pw.TextAlign.left,
}) {
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

  if (segments.isEmpty) {
    return const [];
  }

  return segments.map((line) {
    final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: bottomPadding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 12,
            height: 12,
            child: pw.CustomPaint(
              size: const PdfPoint(12, 12),
              painter: (canvas, size) {
                final cx = size.x / 2;
                final cy = size.y / 2;
                canvas.setStrokeColor(accentColor);
                canvas.setLineWidth(0.9);
                canvas.moveTo(cx, cy - 4);
                canvas.lineTo(cx, cy + 4);
                canvas.strokePath();
                canvas.moveTo(cx - 4, cy);
                canvas.lineTo(cx + 4, cy);
                canvas.strokePath();
                canvas.moveTo(cx - 2.8, cy - 2.8);
                canvas.lineTo(cx + 2.8, cy + 2.8);
                canvas.strokePath();
                canvas.moveTo(cx + 2.8, cy - 2.8);
                canvas.lineTo(cx - 2.8, cy + 2.8);
                canvas.strokePath();
              },
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              cleanLine,
              style: pw.TextStyle(
                fontSize: fontSize,
                lineSpacing: lineSpacing,
                color: textColor,
              ),
              textAlign: textAlign,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

List<pw.Widget> _buildArrowPointerBullets(
  String text,
  PdfColor accentColor, {
  double fontSize = 9.2,
  double lineSpacing = 1.45,
  double bottomPadding = 5,
  PdfColor? textColor,
  pw.TextAlign textAlign = pw.TextAlign.left,
}) {
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

  if (segments.isEmpty) {
    return const [];
  }

  return segments.map((line) {
    final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: bottomPadding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 14,
            height: 12,
            child: pw.CustomPaint(
              size: const PdfPoint(14, 12),
              painter: (canvas, size) {
                canvas.setFillColor(accentColor);
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
              cleanLine,
              textAlign: textAlign,
              style: pw.TextStyle(
                fontSize: fontSize,
                lineSpacing: lineSpacing,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }).toList();
}

void _drawPdfIcon(
  PdfGraphics canvas,
  String iconType,
  double cx,
  double cy,
  double r,
  PdfColor color,
) {
  canvas.setFillColor(color);
  canvas.setStrokeColor(color);

  switch (iconType) {
    case 'phone':
      _drawPhoneIcon(canvas, cx, cy, r);
      break;
    case 'email':
      _drawEmailIcon(canvas, cx, cy, r);
      break;
    case 'location':
      _drawLocationIcon(canvas, cx, cy, r, color);
      break;
    case 'website':
      _drawWebsiteIcon(canvas, cx, cy, r);
      break;
    case 'linkedin':
      _drawLinkedInIcon(canvas, cx, cy, r);
      break;
    default:
      canvas.drawEllipse(cx, cy, r * 0.35, r * 0.35);
      canvas.fillPath();
      break;
  }
}

void _drawPhoneIcon(PdfGraphics canvas, double cx, double cy, double r) {
  canvas.drawEllipse(cx + r * 0.55, cy + r * 0.65, r * 0.42, r * 0.42);
  canvas.fillPath();
  canvas.drawEllipse(cx - r * 0.55, cy - r * 0.65, r * 0.42, r * 0.42);
  canvas.fillPath();
  canvas.setLineWidth(r * 0.48);
  canvas.moveTo(cx + r * 0.2, cy + r * 0.45);
  canvas.curveTo(
    cx + r * 0.65,
    cy + r * 0.05,
    cx - r * 0.65,
    cy - r * 0.05,
    cx - r * 0.2,
    cy - r * 0.45,
  );
  canvas.strokePath();
}

void _drawEmailIcon(PdfGraphics canvas, double cx, double cy, double r) {
  canvas.setLineWidth(r * 0.22);
  final halfWidth = r * 1.05;
  final halfHeight = r * 0.65;
  canvas.moveTo(cx - halfWidth, cy - halfHeight);
  canvas.lineTo(cx + halfWidth, cy - halfHeight);
  canvas.lineTo(cx + halfWidth, cy + halfHeight);
  canvas.lineTo(cx - halfWidth, cy + halfHeight);
  canvas.closePath();
  canvas.strokePath();
  canvas.moveTo(cx - halfWidth, cy + halfHeight);
  canvas.lineTo(cx, cy);
  canvas.lineTo(cx + halfWidth, cy + halfHeight);
  canvas.strokePath();
}

void _drawLocationIcon(
  PdfGraphics canvas,
  double cx,
  double cy,
  double r,
  PdfColor color,
) {
  final headCenterY = cy + r * 0.25;
  canvas.setFillColor(color);
  canvas.drawEllipse(cx, headCenterY, r * 0.78, r * 0.78);
  canvas.fillPath();
  canvas.moveTo(cx - r * 0.5, headCenterY - r * 0.35);
  canvas.lineTo(cx, cy - r * 0.9);
  canvas.lineTo(cx + r * 0.5, headCenterY - r * 0.35);
  canvas.closePath();
  canvas.fillPath();
  canvas.setFillColor(PdfColors.white);
  canvas.drawEllipse(cx, headCenterY, r * 0.32, r * 0.32);
  canvas.fillPath();
}

void _drawWebsiteIcon(PdfGraphics canvas, double cx, double cy, double r) {
  canvas.setLineWidth(r * 0.22);
  canvas.drawEllipse(cx, cy, r, r);
  canvas.strokePath();
  canvas.moveTo(cx - r, cy);
  canvas.lineTo(cx + r, cy);
  canvas.strokePath();
  canvas.moveTo(cx, cy - r);
  canvas.lineTo(cx, cy + r);
  canvas.strokePath();
  canvas.drawEllipse(cx, cy, r * 0.48, r);
  canvas.strokePath();
}

void _drawLinkedInIcon(PdfGraphics canvas, double cx, double cy, double r) {
  canvas.setLineWidth(r * 0.32);
  canvas.drawEllipse(cx - r * 0.42, cy + r * 0.6, r * 0.22, r * 0.22);
  canvas.fillPath();
  canvas.moveTo(cx - r * 0.42, cy + r * 0.25);
  canvas.lineTo(cx - r * 0.42, cy - r * 0.72);
  canvas.strokePath();
  canvas.moveTo(cx + r * 0.08, cy + r * 0.25);
  canvas.lineTo(cx + r * 0.08, cy - r * 0.72);
  canvas.strokePath();
  canvas.moveTo(cx + r * 0.08, cy + r * 0.12);
  canvas.curveTo(
    cx + r * 0.12,
    cy + r * 0.42,
    cx + r * 0.82,
    cy + r * 0.42,
    cx + r * 0.82,
    cy + r * 0.12,
  );
  canvas.lineTo(cx + r * 0.82, cy - r * 0.72);
  canvas.strokePath();
}

PdfColor _scalePdfColor(PdfColor color, double factor, [double alpha = 1]) {
  return PdfColor(
    (color.red * factor).clamp(0.0, 1.0).toDouble(),
    (color.green * factor).clamp(0.0, 1.0).toDouble(),
    (color.blue * factor).clamp(0.0, 1.0).toDouble(),
    alpha,
  );
}

PdfColor _blendPdfWithWhite(PdfColor color, double opacity) {
  final amount = opacity.clamp(0.0, 1.0).toDouble();
  return PdfColor(
    (color.red * amount + (1 - amount)).clamp(0.0, 1.0).toDouble(),
    (color.green * amount + (1 - amount)).clamp(0.0, 1.0).toDouble(),
    (color.blue * amount + (1 - amount)).clamp(0.0, 1.0).toDouble(),
  );
}

pw.Widget _buildContactIconRow(
  String iconType,
  String text,
  PdfColor iconBg, {
  PdfColor iconFg = PdfColors.white,
  PdfColor textColor = PdfColors.grey800,
  double textSize = 9,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.max,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 13,
          height: 13,
          margin: const pw.EdgeInsets.only(right: 5),
          child: pw.CustomPaint(
            size: const PdfPoint(13, 13),
            painter: (canvas, size) {
              final centerX = size.x / 2;
              final centerY = size.y / 2;
              canvas.setFillColor(iconBg);
              canvas.drawEllipse(centerX, centerY, centerX, centerY);
              canvas.fillPath();
              _drawPdfIcon(
                canvas,
                iconType,
                centerX,
                centerY,
                centerX * 0.52,
                iconFg,
              );
            },
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitizePdfText(text),
            maxLines: 2,
            style: pw.TextStyle(fontSize: textSize, color: textColor),
          ),
        ),
      ],
    ),
  );
}

abstract class PdfTemplate {
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor);
}

class ModernTemplate extends PdfTemplate {
  static const PdfColor _midGray = PdfColor.fromInt(0xFF6b7280);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (context) => [
          buildModernHeader(resume, accentColor),
          pw.SizedBox(height: 24),
          if (resume.objective?.isNotEmpty ?? false) ...[
            buildSectionTitle('PROFESSIONAL SUMMARY', accentColor),
            ..._buildSummaryBullets(resume.objective!, accentColor),
            pw.SizedBox(height: 20),
          ],
          if (resume.experience.isNotEmpty) ...[
            buildSectionTitle('WORK EXPERIENCE', accentColor),
            buildTimelineExperience(resume.experience, accentColor),
            pw.SizedBox(height: 12),
          ],
          if (resume.education.isNotEmpty) ...[
            buildSectionTitle('EDUCATION', accentColor),
            buildTimelineEducation(resume.education, accentColor),
            pw.SizedBox(height: 12),
          ],
          if (resume.skills.isNotEmpty) ...[
            buildSectionTitle('SKILLS', accentColor),
            buildSkillsWithBars(resume.skills, accentColor),
            pw.SizedBox(height: 20),
          ],
          if (resume.projects.isNotEmpty) ...[
            buildSectionTitle('PROJECTS', accentColor),
            ...resume.projects.map((proj) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(proj.title,
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      if (proj.description.isNotEmpty)
                        pw.Text(proj.description,
                            style: const pw.TextStyle(
                                fontSize: 9, lineSpacing: 1.5),
                            textAlign: pw.TextAlign.justify),
                      if (proj.technologies.isNotEmpty)
                        pw.Text(
                          'Technologies: ${proj.technologies.join(', ')}',
                          style: pw.TextStyle(fontSize: 9, color: accentColor),
                        ),
                      if (proj.url?.isNotEmpty ?? false)
                        pw.Text(proj.url!,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                )),
          ],
          if (resume.certifications.isNotEmpty) ...[
            buildSectionTitle('CERTIFICATIONS', accentColor),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(cert.name,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${cert.issuer}${cert.credentialId != null && cert.credentialId!.isNotEmpty ? '  ID: ${cert.credentialId}' : ''}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                )),
          ],
          if (resume.languages.isNotEmpty) ...[
            buildSectionTitle('LANGUAGES', accentColor),
            pw.Wrap(
              spacing: 16,
              runSpacing: 6,
              children: resume.languages
                  .map((lang) => pw.Text(
                        '${lang.name}  (${lang.proficiency})',
                        style: const pw.TextStyle(fontSize: 10),
                      ))
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget buildModernHeader(ResumeModel resume, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resume.personalInfo.fullName.isEmpty
                      ? 'Your Name'
                      : resume.personalInfo.fullName,
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white),
                ),
                if (resume.personalInfo.jobTitle?.isNotEmpty ?? false)
                  pw.Text(
                    resume.personalInfo.jobTitle!,
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.white),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 190,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (resume.personalInfo.email.isNotEmpty)
                  buildContactChip(
                      'email', resume.personalInfo.email, accentColor),
                if (resume.personalInfo.phone.isNotEmpty)
                  pw.SizedBox(height: 4),
                if (resume.personalInfo.phone.isNotEmpty)
                  buildContactChip(
                      'phone', resume.personalInfo.phone, accentColor),
                if (resume.personalInfo.address.isNotEmpty)
                  pw.SizedBox(height: 4),
                if (resume.personalInfo.address.isNotEmpty)
                  buildContactChip(
                      'location', resume.personalInfo.address, accentColor),
                if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                  pw.SizedBox(height: 4),
                if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                  buildContactChip(
                      'linkedin', resume.personalInfo.linkedIn!, accentColor),
                if (resume.personalInfo.website?.isNotEmpty ?? false)
                  pw.SizedBox(height: 4),
                if (resume.personalInfo.website?.isNotEmpty ?? false)
                  buildContactChip(
                      'website', resume.personalInfo.website!, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildContactChip(
      String iconLabel, String value, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 14,
            height: 14,
            child: pw.CustomPaint(
              size: const PdfPoint(14, 14),
              painter: (canvas, size) {
                final cx = size.x / 2;
                final cy = size.y / 2;
                canvas.setFillColor(accentColor);
                canvas.drawEllipse(cx, cy, cx, cy);
                canvas.fillPath();
                _drawPdfIcon(
                    canvas, iconLabel, cx, cy, cx * 0.55, PdfColors.white);
              },
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Flexible(
            child: pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 8,
                color: accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildSectionTitle(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accentColor, width: 3)),
      ),
      child: pw.Text(
        _h(title),
        style: pw.TextStyle(
            fontSize: 14, fontWeight: pw.FontWeight.bold, color: accentColor),
      ),
    );
  }

  pw.Widget buildTimelineExperience(
      List<Experience> experiences, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: experiences.map((exp) {
        final dateStr =
            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}';
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(exp.position,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${exp.company}${exp.location != null && exp.location!.isNotEmpty ? ' - ${exp.location}' : ''}',
                      style: pw.TextStyle(fontSize: 10, color: accentColor),
                    ),
                    if (exp.achievements.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      ...exp.achievements.map((r) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('- ',
                                    style: pw.TextStyle(
                                        color: accentColor, fontSize: 10)),
                                pw.Expanded(
                                    child: pw.Text(r,
                                        style: const pw.TextStyle(
                                            fontSize: 9, lineSpacing: 1.5),
                                        textAlign: pw.TextAlign.justify)),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.SizedBox(
                width: 90,
                child: pw.Text(dateStr,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget buildTimelineEducation(
      List<Education> educations, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: educations.map((edu) {
        final dateStr =
            '${DateFormat('yyyy').format(edu.startDate)} - ${edu.isCurrentlyStudying ? _present() : DateFormat('yyyy').format(edu.endDate!)}';
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.degree,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${edu.institution}${edu.location != null && edu.location!.isNotEmpty ? ' - ${edu.location}' : ''}',
                      style: pw.TextStyle(fontSize: 10, color: accentColor),
                    ),
                    if (edu.grade != null && edu.grade!.isNotEmpty)
                      pw.Text('Grade: ${edu.grade}',
                          style:
                              const pw.TextStyle(fontSize: 9, color: _midGray)),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.SizedBox(
                width: 90,
                child: pw.Text(dateStr,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget buildSkillsWithBars(List<Skill> skills, PdfColor accentColor) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 8,
      children: skills
          .map((skill) => pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: accentColor.flatten(),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(16)),
                ),
                child: pw.Text(skill.name,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }
}

class StartupTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final normalizedResume = resume.copyWith(
      customSections: ensureStartupProfileSections(resume),
    );
    final contactItems = _resumeContactValues(normalizedResume);
    final aboutLines = _splitPdfLines(normalizedResume.objective);
    final impactLines = normalizedResume.experience.isNotEmpty
        ? _descriptionFirstExperienceLines(
            normalizedResume.experience.first,
          ).take(2).toList(growable: false)
        : aboutLines.take(2).toList(growable: false);
    final toolLines = _collectStartupToolLines(normalizedResume);
    final extraSections = normalizedResume.customSections
        .where((section) => section.items.isNotEmpty)
        .where((section) => section.id != 'startup_tools')
        .toList(growable: false);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              padding: const pw.EdgeInsets.all(18),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        build: (context) => [
          _buildStartupHeader(normalizedResume, accentColor, contactItems),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildStartupMiniCard(
                  'IMPACT',
                  impactLines,
                  accentColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildStartupMiniCard(
                  'TOOLS',
                  toolLines,
                  accentColor,
                  commaSeparated: true,
                ),
              ),
            ],
          ),
          if (aboutLines.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildStartupSectionTitle('ABOUT', accentColor),
            ..._buildStartupNumberedLines(aboutLines, accentColor),
          ],
          if (normalizedResume.experience.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildStartupSectionTitle('EXPERIENCE', accentColor),
            ...normalizedResume.experience.map(
              (exp) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _buildStartupExperience(exp, accentColor),
              ),
            ),
          ],
          if (normalizedResume.projects.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildStartupSectionTitle('PROJECTS', accentColor),
            ...normalizedResume.projects.map(
              (project) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _buildStartupProject(project, accentColor),
              ),
            ),
          ],
          if (normalizedResume.education.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildStartupSectionTitle('EDUCATION', accentColor),
            ...normalizedResume.education.map(
              (education) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: _buildStartupEducation(education),
              ),
            ),
          ],
          if (normalizedResume.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildStartupSectionTitle('CERTIFICATIONS', accentColor),
            ...normalizedResume.certifications.map(
              (cert) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _buildStartupLine(
                  cert.issuer.isNotEmpty
                      ? '${_sanitizePdfText(cert.name)} - ${_sanitizePdfText(cert.issuer)}'
                      : _sanitizePdfText(cert.name),
                ),
              ),
            ),
          ],
          if (normalizedResume.languages.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildStartupSectionTitle('LANGUAGES', accentColor),
            ...normalizedResume.languages.map(
              (language) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _buildStartupLine(
                  language.proficiency.isNotEmpty
                      ? '${_sanitizePdfText(language.name)} ${_sanitizePdfText(language.proficiency)}'
                      : _sanitizePdfText(language.name),
                ),
              ),
            ),
          ],
          ...extraSections.expand((section) {
            final lines = section.items
                .expand(
                  (item) => [
                    if (item.title.trim().isNotEmpty) item.title,
                    if ((item.subtitle ?? '').trim().isNotEmpty) item.subtitle!,
                    if ((item.description ?? '').trim().isNotEmpty)
                      item.description!,
                  ],
                )
                .expand(_splitStartupSectionText)
                .where((line) => line.isNotEmpty)
                .toList(growable: false);

            if (lines.isEmpty) {
              return const <pw.Widget>[];
            }

            return <pw.Widget>[
              pw.SizedBox(height: 6),
              _buildStartupSectionTitle(section.title, accentColor),
              ...lines.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: _buildStartupLine(line),
                ),
              ),
            ];
          }),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildStartupHeader(
    ResumeModel resume,
    PdfColor accentColor,
    List<String> contactItems,
  ) {
    final headerEnd = _blendPdfWithWhite(accentColor, 0.82);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [accentColor, headerEnd],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            resume.personalInfo.fullName.trim().isEmpty
                ? 'YOUR NAME'
                : _sanitizePdfText(
                    resume.personalInfo.fullName.trim().toUpperCase(),
                  ),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if (resume.personalInfo.jobTitle?.trim().isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                _sanitizePdfText(resume.personalInfo.jobTitle!.trim()),
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor(1, 1, 1, 0.92),
                ),
              ),
            ),
          if (contactItems.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 10,
              runSpacing: 3,
              children: contactItems
                  .map(
                    (item) => pw.Text(
                      item,
                      style: const pw.TextStyle(
                        fontSize: 8.1,
                        color: PdfColor(1, 1, 1, 0.72),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStartupMiniCard(
    String label,
    List<String> lines,
    PdfColor accentColor, {
    bool commaSeparated = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: pw.BoxDecoration(
        color: _blendPdfWithWhite(accentColor, 0.08),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(label),
            style: pw.TextStyle(
              fontSize: 10,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (lines.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            if (commaSeparated)
              pw.Text(
                _sanitizePdfText(lines.join(', ')),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: PdfColor.fromInt(0xFF6B7280),
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              )
            else
              ...lines.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: _buildStartupLine('• $line'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStartupSectionTitle(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _h(title),
        style: pw.TextStyle(
          fontSize: 11.5,
          color: accentColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  List<pw.Widget> _buildStartupNumberedLines(
    List<String> lines,
    PdfColor accentColor,
  ) {
    return lines.asMap().entries.map((entry) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 16,
              child: pw.Text(
                '${entry.key + 1}.',
                style: pw.TextStyle(
                  fontSize: 9.2,
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(entry.value),
                style: const pw.TextStyle(
                  fontSize: 9.2,
                  color: PdfColor.fromInt(0xFF6B7280),
                  lineSpacing: 1.35,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  pw.Widget _buildStartupExperience(Experience exp, PdfColor accentColor) {
    final metaParts = <String>[
      if (exp.company.trim().isNotEmpty) _sanitizePdfText(exp.company.trim()),
      '${exp.startDate.year} - ${exp.isCurrentlyWorking ? _present() : (exp.endDate?.year.toString() ?? _present())}',
      if ((exp.location ?? '').trim().isNotEmpty)
        _sanitizePdfText(exp.location!.trim()),
    ];
    final details = _descriptionFirstExperienceLines(exp);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(exp.position),
          style: pw.TextStyle(
            fontSize: 12.4,
            color: const PdfColor.fromInt(0xFF111827),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          _sanitizePdfText(metaParts.join('  •  ')),
          style: const pw.TextStyle(
            fontSize: 9.2,
            color: PdfColor.fromInt(0xFF6B7280),
          ),
        ),
        if (details.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...details.map(
            (detail) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      fontSize: 9.2,
                      color: accentColor,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(detail),
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        color: PdfColor.fromInt(0xFF6B7280),
                        lineSpacing: 1.3,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildStartupProject(Project project, PdfColor accentColor) {
    final detailLines = _splitPdfLines(project.description);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(project.title),
          style: pw.TextStyle(
            fontSize: 11.2,
            color: const PdfColor.fromInt(0xFF111827),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (detailLines.isNotEmpty)
          ...detailLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(line),
                style: const pw.TextStyle(
                  fontSize: 8.9,
                  color: PdfColor.fromInt(0xFF6B7280),
                  lineSpacing: 1.3,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ),
        if (project.technologies.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              'Tools: ${project.technologies.map(_sanitizePdfText).join(', ')}',
              style: pw.TextStyle(
                fontSize: 8.4,
                color: accentColor,
              ),
            ),
          ),
        if ((project.url ?? '').trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              _sanitizePdfText(project.url!.trim()),
              style: pw.TextStyle(
                fontSize: 8.5,
                color: accentColor,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildStartupEducation(Education education) {
    final metaParts = <String>[
      if (education.institution.trim().isNotEmpty)
        _sanitizePdfText(education.institution.trim()),
      '${education.startDate.year} - ${education.isCurrentlyStudying ? _present() : (education.endDate?.year.toString() ?? education.startDate.year.toString())}',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(
            education.degree.isNotEmpty
                ? education.degree
                : education.fieldOfStudy,
          ),
          style: pw.TextStyle(
            fontSize: 11.0,
            color: const PdfColor.fromInt(0xFF111827),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          _sanitizePdfText(metaParts.join('  •  ')),
          style: const pw.TextStyle(
            fontSize: 8.9,
            color: PdfColor.fromInt(0xFF6B7280),
          ),
        ),
        if (education.fieldOfStudy.isNotEmpty && education.degree.isNotEmpty)
          pw.Text(
            _sanitizePdfText(education.fieldOfStudy),
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: PdfColor.fromInt(0xFF6B7280),
            ),
          ),
        if ((education.grade ?? '').isNotEmpty)
          pw.Text(
            'Grade: ${_sanitizePdfText(education.grade!)}',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PdfColor.fromInt(0xFF6B7280),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildStartupLine(String text) {
    return pw.Text(
      _sanitizePdfText(text),
      style: const pw.TextStyle(
        fontSize: 8.9,
        color: PdfColor.fromInt(0xFF6B7280),
        lineSpacing: 1.3,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }
}

class DeveloperTemplate extends PdfTemplate {
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
    if (resume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _buildDeveloperSectionTitle('SUMMARY', accentColor),
        _buildDeveloperSummary(resume.objective!, accentColor),
        pw.SizedBox(height: 16),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildDeveloperSectionTitle('TECH STACK', accentColor),
        _buildDeveloperSkills(resume, accentColor),
        pw.SizedBox(height: 16),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildDeveloperSectionTitle('EXPERIENCE', accentColor),
        ...resume.experience
            .map((exp) => _buildDeveloperExperience(exp, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildDeveloperSectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildDeveloperProject(project, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildDeveloperSectionTitle('EDUCATION', accentColor),
        ...resume.education
            .map((edu) => _buildDeveloperEducation(edu, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildDeveloperSectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications
            .map((cert) => _buildDeveloperCertification(cert, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildDeveloperSectionTitle('LANGUAGES', accentColor),
        pw.Text(
          resume.languages
              .map((lang) =>
                  '${_sanitizePdfText(lang.name)} (${_sanitizePdfText(lang.proficiency)})')
              .join('   |   '),
          style: const pw.TextStyle(fontSize: 9.2, color: _ink),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    final contactWidgets = <pw.Widget>[
      if (resume.personalInfo.email.isNotEmpty)
        _buildDeveloperContact('email', resume.personalInfo.email, accentColor),
      if (resume.personalInfo.phone.isNotEmpty)
        _buildDeveloperContact('phone', resume.personalInfo.phone, accentColor),
      if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
        _buildDeveloperContact(
            'linkedin', resume.personalInfo.linkedIn!, accentColor),
      if (resume.personalInfo.website?.isNotEmpty ?? false)
        _buildDeveloperContact(
            'website', resume.personalInfo.website!, accentColor),
      if (resume.personalInfo.github?.isNotEmpty ?? false)
        _buildDeveloperContact(
            'website', resume.personalInfo.github!, accentColor),
      if (resume.personalInfo.address.isNotEmpty)
        _buildDeveloperContact(
            'location', resume.personalInfo.address, accentColor),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
        build: (context) => [
          pw.Container(
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
                  _sanitizePdfText(
                    resume.personalInfo.fullName.isEmpty
                        ? 'YOUR NAME'
                        : resume.personalInfo.fullName,
                  ),
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (resume.personalInfo.jobTitle?.isNotEmpty ?? false)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      _sanitizePdfText(resume.personalInfo.jobTitle!),
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: _scalePdfColor(accentColor, 0.7, 1.0),
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                if (contactWidgets.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: contactWidgets,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildDeveloperContact(
      String icon, String value, PdfColor accentColor) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 11,
          height: 11,
          margin: const pw.EdgeInsets.only(right: 4),
          child: pw.CustomPaint(
            size: const PdfPoint(11, 11),
            painter: (canvas, size) {
              final cx = size.x / 2;
              final cy = size.y / 2;
              canvas.setFillColor(accentColor);
              canvas.drawEllipse(cx, cy, cx, cy);
              canvas.fillPath();
              _drawPdfIcon(canvas, icon, cx, cy, cx * 0.52, _hero);
            },
          ),
        ),
        pw.Text(
          _sanitizePdfText(value),
          style: const pw.TextStyle(fontSize: 8.1, color: PdfColors.white),
        ),
      ],
    );
  }

  pw.Widget _buildDeveloperSectionTitle(String title, PdfColor accentColor) {
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
                    child: pw.Container(
                      width: 2.6,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperSummary(String text, PdfColor accentColor) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 4,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildSparkSummaryBullets(
                text,
                accentColor,
                fontSize: 9.2,
                lineSpacing: 1.45,
                bottomPadding: 4,
                textColor: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperSkills(ResumeModel resume, PdfColor accentColor) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resume.skills
          .map(
            (skill) => pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _hero,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: accentColor, width: 0.8),
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
          .toList(),
    );
  }

  pw.Widget _buildDeveloperExperience(Experience exp, PdfColor accentColor) {
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
                      _sanitizePdfText(exp.position),
                      style: pw.TextStyle(
                        fontSize: 11.4,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Text(
                      _sanitizePdfText(
                        '${exp.company}${exp.location != null && exp.location!.isNotEmpty ? '  |  ${exp.location}' : ''}',
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
                  '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_collectExperienceLines(exp).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ..._buildExperienceLineWidgets(
              exp,
              accentColor,
              fontSize: 8.8,
              leftPadding: 2,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperProject(Project project, PdfColor accentColor) {
    return pw.Container(
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
                fontSize: 10.6, fontWeight: pw.FontWeight.bold, color: _ink),
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
                  fontSize: 8.8, color: _ink, lineSpacing: 1.45),
            ),
          if (project.url?.isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                _sanitizePdfText(project.url!),
                style: const pw.TextStyle(fontSize: 8.2, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperEducation(Education edu, PdfColor accentColor) {
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
                      edu.degree.isEmpty ? edu.fieldOfStudy : edu.degree),
                  style: pw.TextStyle(
                      fontSize: 10.4,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink),
                ),
                pw.Text(
                  _sanitizePdfText(edu.institution),
                  style: pw.TextStyle(fontSize: 8.8, color: accentColor),
                ),
                if (edu.location?.isNotEmpty ?? false)
                  pw.Text(
                    _sanitizePdfText(edu.location!),
                    style: const pw.TextStyle(fontSize: 8.2, color: _muted),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            '${DateFormat('yyyy').format(edu.startDate)} - ${edu.isCurrentlyStudying ? _present() : DateFormat('yyyy').format(edu.endDate!)}',
            style: const pw.TextStyle(fontSize: 8.2, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperCertification(
      Certification cert, PdfColor accentColor) {
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
              '${_sanitizePdfText(cert.name)}${cert.issuer.isNotEmpty ? '  |  ${_sanitizePdfText(cert.issuer)}' : ''}',
              style: const pw.TextStyle(fontSize: 8.8, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

class CreativeTemplate extends PdfTemplate {
  static const PdfColor _ink = PdfColor.fromInt(0xFF2D3142);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFFFF8F1);
  static const PdfColor _softCard = PdfColor.fromInt(0xFFFFFBF5);
  static const PdfColor _headerMuted = PdfColor(1, 1, 1, 0.76);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);

    final sections = <String, List<pw.Widget>>{};
    if (resume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _sectionTitle('PROFILE', accentColor),
        ..._buildProfileParagraphs(resume.objective!),
        pw.SizedBox(height: 12),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _sectionTitle('EXPERIENCE', accentColor),
        ...resume.experience.map((exp) => _experienceCard(exp, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _sectionTitle('EDUCATION', accentColor),
        ...resume.education.map((edu) => _educationBlock(edu, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _sectionTitle('SKILLS', accentColor),
        pw.Wrap(
          spacing: 8,
          runSpacing: 6,
          children: resume.skills
              .map((skill) => _skillChip(skill.name, accentColor))
              .toList(),
        ),
        pw.SizedBox(height: 10),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _sectionTitle('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _projectBlock(project, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _sectionTitle('CERTIFICATIONS', accentColor),
        ...resume.certifications
            .map((cert) => _certificationBlock(cert, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _sectionTitle('LANGUAGES', accentColor),
        ...resume.languages.map(_languageLine),
        pw.SizedBox(height: 8),
      ];
    }
    for (final section
        in resume.customSections.where((section) => section.items.isNotEmpty)) {
      sections[section.id] = [
        _sectionTitle(section.title.toUpperCase(), accentColor,
            translate: false),
        ...section.items.map((item) => _customSectionItem(item, accentColor)),
        pw.SizedBox(height: 8),
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: _pageBg,
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(14)),
                    border: pw.Border.all(
                      color: _scalePdfColor(accentColor, 1.0, 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        header: (context) =>
            context.pageNumber == 1 ? pw.SizedBox() : pw.SizedBox(height: 16),
        build: (context) => [
          _buildHeader(resume, accentColor),
          pw.SizedBox(height: 16),
          ..._applyPdfSectionOrder(sectionOrder, sections).map(
            (widget) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 18),
              child: widget,
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(ResumeModel resume, PdfColor accentColor) {
    final contactLines = <String>[
      if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
      if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
      if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
        resume.personalInfo.linkedIn!,
      if ((resume.personalInfo.github ?? '').isNotEmpty)
        resume.personalInfo.github!,
      if ((resume.personalInfo.website ?? '').isNotEmpty)
        resume.personalInfo.website!,
      if (resume.personalInfo.address.isNotEmpty) resume.personalInfo.address,
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(14),
          topRight: pw.Radius.circular(14),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(
              resume.personalInfo.fullName.isEmpty
                  ? 'Your Name'
                  : resume.personalInfo.fullName,
            ),
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(resume.personalInfo.jobTitle!),
                style: pw.TextStyle(
                  fontSize: 13,
                  color: _scalePdfColor(accentColor, 1.0, 0.95),
                ),
              ),
            ),
          if (contactLines.isNotEmpty) ...[
            pw.SizedBox(height: 7),
            ...contactLines.map(_buildHeaderContactLine),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildHeaderContactLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          _sanitizePdfText(text),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _headerMuted,
            lineSpacing: 1.2,
          ),
        ),
      );

  pw.Widget _sectionTitle(
    String title,
    PdfColor accentColor, {
    bool translate = true,
  }) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        ),
        child: pw.Text(
          translate ? _h(title) : _sanitizePdfText(title),
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
      );

  List<pw.Widget> _buildProfileParagraphs(String text) {
    final paragraphs = _sanitizePdfText(text)
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final items =
        paragraphs.isNotEmpty ? paragraphs : [_sanitizePdfText(text).trim()];

    return items
        .where((item) => item.isNotEmpty)
        .map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              item,
              style: const pw.TextStyle(
                fontSize: 9.2,
                color: _ink,
                lineSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        )
        .toList();
  }

  pw.Widget _experienceCard(Experience exp, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _softCard,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _scalePdfColor(accentColor, 1.0, 0.18)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizePdfText(exp.position),
                        style: pw.TextStyle(
                          fontSize: 10.8,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _sanitizePdfText(exp.company),
                          style:
                              pw.TextStyle(fontSize: 9.2, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 120,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _monthRange(
                          exp.startDate,
                          exp.endDate,
                          exp.isCurrentlyWorking,
                        ),
                        style: const pw.TextStyle(fontSize: 8.8, color: _muted),
                        textAlign: pw.TextAlign.right,
                      ),
                      if ((exp.location ?? '').isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            _sanitizePdfText(exp.location!),
                            style: const pw.TextStyle(
                                fontSize: 8.6, color: _muted),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_collectExperienceLines(exp).isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ..._collectExperienceLines(exp)
                  .map((line) => _creativeExperienceLine(line, accentColor)),
            ],
          ],
        ),
      );

  pw.Widget _creativeExperienceLine(String line, PdfColor accentColor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '• ',
              style: pw.TextStyle(fontSize: 8.8, color: accentColor),
            ),
            pw.Expanded(
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _muted,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );

  pw.Widget _educationBlock(Education edu, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(
                      edu.degree.isEmpty ? edu.fieldOfStudy : edu.degree,
                    ),
                    style: pw.TextStyle(
                      fontSize: 10.2,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      _sanitizePdfText(
                        [
                          edu.institution,
                          if ((edu.location ?? '').isNotEmpty) edu.location!,
                        ].where((item) => item.trim().isNotEmpty).join(' • '),
                      ),
                      style: const pw.TextStyle(fontSize: 8.9, color: _muted),
                    ),
                  ),
                  if ((edu.grade ?? '').isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        'Grade: ${_sanitizePdfText(edu.grade!)}',
                        style: const pw.TextStyle(fontSize: 8.4, color: _ink),
                      ),
                    ),
                  if ((edu.description ?? '').isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        _sanitizePdfText(edu.description!),
                        style: const pw.TextStyle(
                          fontSize: 8.4,
                          color: _muted,
                          lineSpacing: 1.4,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 72,
              child: pw.Text(
                _yearRange(edu.startDate, edu.endDate, edu.isCurrentlyStudying),
                style: const pw.TextStyle(fontSize: 8.6, color: _muted),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );

  pw.Widget _skillChip(String label, PdfColor accentColor) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: _scalePdfColor(accentColor, 0.9, 1.0)),
        ),
        child: pw.Text(
          _sanitizePdfText(label),
          style: pw.TextStyle(
            fontSize: 8.4,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  pw.Widget _projectBlock(Project project, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _sanitizePdfText(project.title),
              style: pw.TextStyle(
                fontSize: 10.4,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            if (project.description.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  _sanitizePdfText(project.description),
                  style: const pw.TextStyle(
                    fontSize: 8.9,
                    color: _muted,
                    lineSpacing: 1.4,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            if (project.technologies.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  project.technologies.map(_sanitizePdfText).join(' • '),
                  style: pw.TextStyle(fontSize: 8.2, color: accentColor),
                ),
              ),
            if ((project.url ?? '').trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  _sanitizePdfText(project.url!),
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

  pw.Widget _certificationBlock(Certification cert, PdfColor accentColor) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _sanitizePdfText(cert.name),
              style: pw.TextStyle(
                fontSize: 9,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (_certificationMeta(cert).isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _certificationMeta(cert),
                  style: const pw.TextStyle(fontSize: 8.4, color: _muted),
                ),
              ),
            if ((cert.credentialId ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  '${_h('Credential ID')}: ${_sanitizePdfText(cert.credentialId!)}',
                  style: pw.TextStyle(fontSize: 8.2, color: accentColor),
                ),
              ),
            if ((cert.credentialUrl ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _sanitizePdfText(cert.credentialUrl!),
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

  pw.Widget _languageLine(Language language) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})',
          style: const pw.TextStyle(fontSize: 8.8, color: _muted),
        ),
      );

  pw.Widget _customSectionItem(CustomSectionItem item, PdfColor accentColor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    _sanitizePdfText(item.title),
                    style: pw.TextStyle(
                      fontSize: 9.4,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (item.date != null)
                  pw.Text(
                    _pdfDate(item.date!),
                    style: const pw.TextStyle(fontSize: 8.4, color: _muted),
                  ),
              ],
            ),
            if ((item.subtitle ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _sanitizePdfText(item.subtitle!),
                  style: pw.TextStyle(fontSize: 8.6, color: accentColor),
                ),
              ),
            if ((item.description ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  _sanitizePdfText(item.description!),
                  style: const pw.TextStyle(
                    fontSize: 8.6,
                    color: _muted,
                    lineSpacing: 1.4,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
          ],
        ),
      );

  String _monthRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText = isCurrent || end == null
        ? _present()
        : _pdfDate(end);
    return '${_pdfDate(start)} - $endText';
  }

  String _yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText =
        isCurrent || end == null ? _present() : DateFormat('yyyy').format(end);
    return '${DateFormat('yyyy').format(start)} - $endText';
  }

  String _certificationMeta(Certification cert) {
    final parts = <String>[];
    if (cert.issuer.isNotEmpty) {
      parts.add(_sanitizePdfText(cert.issuer));
    }
    if (cert.issueDate != null) {
      parts.add('${_h('Issued')} ${_pdfDate(cert.issueDate!)}');
    }
    if (cert.expiryDate != null) {
      parts.add('${_h('Expires')} ${_pdfDate(cert.expiryDate!)}');
    }
    return parts.join(' • ');
  }
}

class ClassicTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    // Add professional role sections if this is a role-specific template
    final normalizedResume = resume.templateId == 'executive'
        ? resume.copyWith(
            customSections: ensureProfessionalRoleSections(resume))
        : resume;
    final sectionOrder = await _loadPdfSectionOrder(normalizedResume);

    final sections = <String, List<pw.Widget>>{};
    if (resume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _buildClassicSection('OBJECTIVE', accentColor),
        ..._buildSummaryBullets(resume.objective!, accentColor),
        pw.SizedBox(height: 16),
      ];
    }
    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _buildClassicSection('PROFESSIONAL EXPERIENCE', accentColor),
        ...resume.experience
            .map((exp) => _buildClassicExperience(exp, accentColor)),
      ];
    }
    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _buildClassicSection('EDUCATION', accentColor),
        ...resume.education
            .map((edu) => _buildClassicEducation(edu, accentColor)),
      ];
    }
    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _buildClassicSection('SKILLS', accentColor),
        pw.Text(
          resume.skills
              .map((skill) => _sanitizePdfText(skill.name))
              .join('  /  '),
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5),
        ),
        pw.SizedBox(height: 14),
      ];
    }
    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _buildClassicSection('PROJECTS', accentColor),
        ...resume.projects
            .map((project) => _buildClassicProject(project, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }
    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _buildClassicSection('CERTIFICATIONS', accentColor),
        ...resume.certifications
            .map((cert) => _buildClassicCertification(cert, accentColor)),
        pw.SizedBox(height: 12),
      ];
    }
    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _buildClassicSection('LANGUAGES', accentColor),
        pw.Text(
          resume.languages
              .map((lang) =>
                  '${_sanitizePdfText(lang.name)} (${_sanitizePdfText(lang.proficiency)})')
              .join('   '),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    // Add custom sections for role-specific templates
    if (resume.templateId == 'executive') {
      for (final section in normalizedResume.customSections) {
        if (section.items.isEmpty) {
          continue;
        }
        sections[section.id] = [
          _buildClassicSection(section.title.toUpperCase(), accentColor),
          ...section.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 12,
                      child: pw.CustomPaint(
                        size: const PdfPoint(12, 12),
                        painter: (canvas, size) {
                          canvas.setFillColor(accentColor);
                          canvas.drawEllipse(6, 6, 2.5, 2.5);
                          canvas.fillPath();
                        },
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(item.title),
                            style: const pw.TextStyle(
                                fontSize: 10, lineSpacing: 1.6),
                            textAlign: pw.TextAlign.left,
                          ),
                          if ((item.subtitle ?? '').trim().isNotEmpty)
                            pw.Text(
                              _sanitizePdfText(item.subtitle!),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          if ((item.description ?? '').trim().isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                _sanitizePdfText(item.description!),
                                style: const pw.TextStyle(
                                  fontSize: 8.8,
                                  color: PdfColors.grey700,
                                  lineSpacing: 1.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 12),
        ];
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 40),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF2ECE5),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
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
                            resume.personalInfo.fullName.isEmpty
                                ? 'YOUR NAME'
                                : _sanitizePdfText(
                                    resume.personalInfo.fullName),
                            style: pw.TextStyle(
                              fontSize: 25,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (resume.personalInfo.jobTitle?.isNotEmpty ?? false)
                      pw.SizedBox(
                        width: 110,
                        child: pw.Align(
                          alignment: pw.Alignment.topRight,
                          child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.jobTitle!),
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: PdfColors.grey700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (resume.personalInfo.email.isNotEmpty)
                      _buildClassicHeaderItem(
                          'email', resume.personalInfo.email, accentColor),
                    if (resume.personalInfo.phone.isNotEmpty)
                      _buildClassicHeaderItem(
                          'phone', resume.personalInfo.phone, accentColor),
                    if (resume.personalInfo.address.isNotEmpty)
                      _buildClassicHeaderItem(
                          'location', resume.personalInfo.address, accentColor),
                    if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                      _buildClassicHeaderItem('linkedin',
                          resume.personalInfo.linkedIn!, accentColor),
                    if (resume.personalInfo.website?.isNotEmpty ?? false)
                      _buildClassicHeaderItem(
                          'website', resume.personalInfo.website!, accentColor),
                    if (resume.personalInfo.github?.isNotEmpty ?? false)
                      _buildClassicHeaderItem(
                          'website', resume.personalInfo.github!, accentColor),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 1,
                width: double.infinity,
                color: PdfColors.grey800,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildClassicHeaderItem(
      String icon, String value, PdfColor accentColor) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          margin: const pw.EdgeInsets.only(right: 4),
          child: pw.CustomPaint(
            size: const PdfPoint(12, 12),
            painter: (canvas, size) {
              final cx = size.x / 2;
              final cy = size.y / 2;
              canvas.setFillColor(accentColor);
              canvas.drawEllipse(cx, cy, cx, cy);
              canvas.fillPath();
              _drawPdfIcon(canvas, icon, cx, cy, cx * 0.5, PdfColors.white);
            },
          ),
        ),
        pw.Text(
          _sanitizePdfText(value),
          style: const pw.TextStyle(fontSize: 8.1, color: PdfColors.grey800),
        ),
      ],
    );
  }

  pw.Widget _buildClassicSection(String title, PdfColor accentColor) {
    return _buildRightBarSectionHeader(
      title,
      textColor: PdfColors.grey900,
      dividerColor: PdfColors.grey400,
      barColor: accentColor,
      fontSize: 12,
      letterSpacing: 0.9,
      marginBottom: 12,
      titleBottomSpacing: 4,
      barHeight: 12,
    );
  }

  pw.Widget _buildClassicExperience(Experience exp, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(exp.position),
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 98,
                child: pw.Text(
                  '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(
              '${exp.company}${exp.location != null && exp.location!.isNotEmpty ? ' - ${exp.location}' : ''}',
            ),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
          if (_collectExperienceLines(exp).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._buildExperienceLineWidgets(
              exp,
              accentColor,
              fontSize: 9,
              leftPadding: 16,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildClassicEducation(Education edu, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(edu.degree),
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                DateFormat('yyyy').format(edu.endDate ?? edu.startDate),
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ],
          ),
          pw.Text(
            _sanitizePdfText(
              '${edu.institution}${edu.location != null && edu.location!.isNotEmpty ? ' - ${edu.location}' : ''}',
            ),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
          if (edu.grade != null && edu.grade!.isNotEmpty)
            pw.Text(
              'Grade: ${edu.grade}',
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildClassicProject(Project project, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
          if (project.description.isNotEmpty)
            pw.Text(
              _sanitizePdfText(project.description),
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.45),
              textAlign: pw.TextAlign.justify,
            ),
          if (project.technologies.isNotEmpty)
            pw.Text(
              'Stack: ${project.technologies.map(_sanitizePdfText).join(', ')}',
              style:
                  const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          if (project.url?.isNotEmpty ?? false)
            pw.Text(
              _sanitizePdfText(project.url!),
              style: pw.TextStyle(fontSize: 8.5, color: accentColor),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildClassicCertification(
      Certification cert, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              _sanitizePdfText(cert.name),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _sanitizePdfText(cert.issuer),
                style: pw.TextStyle(fontSize: 8.8, color: accentColor),
              ),
              if ((cert.credentialId ?? '').isNotEmpty)
                pw.Text(
                  _sanitizePdfText(cert.credentialId!),
                  style: const pw.TextStyle(
                      fontSize: 8.1, color: PdfColors.grey700),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two Column Template - Sidebar layout
class TwoColumnTemplate extends PdfTemplate {
  static const PdfColor _navyDark = PdfColor.fromInt(0xFF1e2d3d);
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
    final objectiveLines = _splitTwoColumnSummaryLines(resume.objective ?? '');
    final leadExperienceCount = _twoColumnLeadExperienceCount(
      objectiveLines.length,
      resume.experience.length,
    );
    final leadExperiences =
        resume.experience.take(leadExperienceCount).toList();
    final overflowExperiences =
        resume.experience.skip(leadExperienceCount).toList();
    final leadEducationCount = overflowExperiences.isEmpty
        ? _twoColumnLeadEducationCount(objectiveLines.length)
        : 0;
    final leadEducation = resume.education.take(leadEducationCount).toList();
    final overflowEducation =
        resume.education.skip(leadEducationCount).toList();
    final leadProjectCount = overflowExperiences.isEmpty
        ? _twoColumnLeadProjectCount(objectiveLines.length)
        : 0;
    final leadProjects = resume.projects.take(leadProjectCount).toList();
    final overflowProjects = resume.projects.skip(leadProjectCount).toList();
    final mainSectionOrder = sectionOrder
        .where(
          (sectionId) => const [
            'summary',
            'experience',
            'education',
            'projects'
          ].contains(sectionId),
        )
        .toList(growable: false);
    final sidebarSkills = resume.skills.take(6).toList();
    final sidebarLanguages = resume.languages.take(4).toList();
    final sidebarCertifications = resume.certifications.take(3).toList();

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
          buildBackground: (context) => pw.Container(color: _pageTint),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderBar(resume, accentColor),
            pw.SizedBox(height: 12),
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildTwoColumnSidebar(
                    resume,
                    accentColor,
                    skills: sidebarSkills,
                    languages: sidebarLanguages,
                    certifications: sidebarCertifications,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildTwoColumnLeadMain(
                      accentColor,
                      sectionOrder: mainSectionOrder,
                      objectiveLines: objectiveLines,
                      experiences: leadExperiences,
                      education: leadEducation,
                      projects: leadProjects,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final overflowSections = <String, List<pw.Widget>>{};
    if (overflowExperiences.isNotEmpty) {
      overflowSections['experience'] = [
        _buildMainSectionTitle('EXPERIENCE', accentColor),
        ...overflowExperiences
            .map((exp) => _buildTwoColumnExperienceCard(exp, accentColor)),
      ];
    }
    if (overflowProjects.isNotEmpty) {
      overflowSections['projects'] = [
        _buildMainSectionTitle('PROJECTS', accentColor),
        ...overflowProjects
            .map((proj) => _buildTwoColumnProjectCard(proj, accentColor)),
      ];
    }
    if (overflowEducation.isNotEmpty) {
      overflowSections['education'] = [
        _buildMainSectionTitle('EDUCATION', accentColor),
        ...overflowEducation
            .map((edu) => _buildTwoColumnEducationCard(edu, accentColor)),
      ];
    }

    if (overflowSections.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                color: _pageTint,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.SizedBox(width: 24),
                    pw.Container(width: 150, color: _sidebarTint),
                    pw.Expanded(child: pw.SizedBox()),
                    pw.SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),
          build: (context) => [
            ..._applyPdfSectionOrder(sectionOrder, overflowSections).map(
              (widget) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 162),
                child: widget,
              ),
            ),
          ],
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildTwoColumnLeadMain(
    PdfColor accentColor, {
    required List<String> sectionOrder,
    required List<String> objectiveLines,
    required List<Experience> experiences,
    required List<Education> education,
    required List<Project> projects,
  }) {
    final leadSections = <String, List<pw.Widget>>{};
    if (objectiveLines.isNotEmpty) {
      leadSections['summary'] = [
        _buildTwoColumnSectionCard(
          'OBJECTIVE',
          _buildTwoColumnSummaryBulletsFromLines(objectiveLines, accentColor),
          accentColor,
        ),
        pw.SizedBox(height: 10),
      ];
    }
    if (experiences.isNotEmpty) {
      leadSections['experience'] = [
        _buildMainSectionTitle('EXPERIENCE', accentColor),
        ...experiences.map(
          (exp) => _buildTwoColumnExperienceCard(
            exp,
            accentColor,
            maxBulletCount: 3,
          ),
        ),
      ];
    }
    if (education.isNotEmpty) {
      leadSections['education'] = [
        pw.SizedBox(height: 4),
        _buildTwoColumnSectionCard(
          'EDUCATION',
          education
              .map((entry) => _buildTwoColumnEducationSnippet(entry))
              .toList(),
          accentColor,
        ),
      ];
    }
    if (projects.isNotEmpty) {
      leadSections['projects'] = [
        pw.SizedBox(height: 8),
        _buildMainSectionTitle('PROJECTS', accentColor),
        ...projects.map(
          (project) => _buildTwoColumnProjectCard(
            project,
            accentColor,
            maxDescriptionLines: 2,
          ),
        ),
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _applyPdfSectionOrder(sectionOrder, leadSections),
    );
  }

  pw.Widget _buildHeaderBar(ResumeModel resume, PdfColor accentColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            resume.personalInfo.fullName.isEmpty
                ? 'YOUR NAME'
                : _sanitizePdfText(resume.personalInfo.fullName).toUpperCase(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          if (resume.personalInfo.jobTitle?.isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(resume.personalInfo.jobTitle!),
                style:
                    const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTwoColumnSidebar(
    ResumeModel resume,
    PdfColor accentColor, {
    required List<Skill> skills,
    required List<Language> languages,
    required List<Certification> certifications,
  }) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: const pw.BoxDecoration(
        color: _sidebarTint,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (skills.isNotEmpty) ...[
            _buildSidebarHeading('SKILLS', accentColor),
            ...skills.map((skill) => _buildSidebarBullet(skill.name)),
            pw.SizedBox(height: 8),
          ],
          if (resume.personalInfo.email.isNotEmpty ||
              resume.personalInfo.phone.isNotEmpty ||
              resume.personalInfo.address.isNotEmpty ||
              (resume.personalInfo.linkedIn?.isNotEmpty ?? false) ||
              (resume.personalInfo.website?.isNotEmpty ?? false)) ...[
            _buildSidebarHeading('CONTACT', accentColor),
            if (resume.personalInfo.email.isNotEmpty)
              _buildSidebarText(resume.personalInfo.email),
            if (resume.personalInfo.phone.isNotEmpty)
              _buildSidebarText(resume.personalInfo.phone),
            if (resume.personalInfo.address.isNotEmpty)
              _buildSidebarText(resume.personalInfo.address),
            if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
              _buildSidebarText(resume.personalInfo.linkedIn!),
            if (resume.personalInfo.website?.isNotEmpty ?? false)
              _buildSidebarText(resume.personalInfo.website!),
            pw.SizedBox(height: 8),
          ],
          if (languages.isNotEmpty) ...[
            _buildSidebarHeading('LANGUAGES', accentColor),
            ...languages.map(
              (lang) => _buildSidebarText(
                '${lang.name}${lang.proficiency.isNotEmpty ? ' (${lang.proficiency})' : ''}',
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          if (certifications.isNotEmpty) ...[
            _buildSidebarHeading('CERTIFICATIONS', accentColor),
            ...certifications.map(
              (cert) => _buildSidebarText(
                '${cert.name}${cert.issuer.isNotEmpty ? ' - ${cert.issuer}' : ''}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTwoColumnSectionCard(
    String title,
    List<pw.Widget> children,
    PdfColor accentColor,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildMainSectionTitle(title, accentColor),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildTwoColumnEducationSnippet(Education edu) {
    final end = edu.isCurrentlyStudying
        ? _present()
        : DateFormat('yyyy').format(edu.endDate ?? edu.startDate);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText('${edu.degree} ${edu.fieldOfStudy}'.trim()),
            style: pw.TextStyle(
              fontSize: 8,
              color: _navyDark,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '${_sanitizePdfText(edu.institution)}  •  ${DateFormat('yyyy').format(edu.startDate)} - $end',
            style: const pw.TextStyle(fontSize: 6.8, color: _mutedText),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTwoColumnEducationCard(Education edu, PdfColor accentColor) {
    return _buildTwoColumnSectionCard(
      'EDUCATION',
      [_buildTwoColumnEducationSnippet(edu)],
      accentColor,
    );
  }

  pw.Widget _buildTwoColumnExperienceCard(
    Experience exp,
    PdfColor accentColor, {
    int maxBulletCount = 4,
  }) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(exp.position),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _navyDark,
            ),
          ),
          pw.Text(
            _sanitizePdfText(exp.company),
            style: pw.TextStyle(fontSize: 7.2, color: accentColor),
          ),
          pw.Text(
            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
            style: const pw.TextStyle(fontSize: 6.6, color: _mutedText),
          ),
          if (exp.achievements.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            ..._buildTwoColumnSummaryBullets(
              exp.achievements.join('\n'),
              accentColor,
              maxItems: maxBulletCount,
            ),
          ] else if (exp.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            ..._buildTwoColumnSummaryBullets(
              exp.description,
              accentColor,
              maxItems: maxBulletCount,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTwoColumnProjectCard(
    Project proj,
    PdfColor accentColor, {
    int maxDescriptionLines = 4,
  }) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(proj.title),
            style: pw.TextStyle(
              fontSize: 8.2,
              fontWeight: pw.FontWeight.bold,
              color: _navyDark,
            ),
          ),
          if (proj.description.isNotEmpty)
            pw.Text(
              _sanitizePdfText(proj.description),
              maxLines: maxDescriptionLines,
              style: const pw.TextStyle(
                fontSize: 7,
                color: _bodyText,
                lineSpacing: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildTwoColumnSummaryBullets(
      String text, PdfColor accentColor,
      {int? maxItems}) {
    final segments = _splitTwoColumnSummaryLines(text);

    final visibleSegments = maxItems == null
        ? segments
        : segments.take(maxItems).toList(growable: false);

    if (visibleSegments.isEmpty) {
      return const [];
    }

    return visibleSegments.map((line) {
      return _buildTwoColumnSummaryBulletRow(line, accentColor);
    }).toList();
  }

  List<String> _splitTwoColumnSummaryLines(String text) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.isNotEmpty
        ? lines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
  }

  List<pw.Widget> _buildTwoColumnSummaryBulletsFromLines(
    List<String> lines,
    PdfColor accentColor,
  ) {
    if (lines.isEmpty) {
      return const [];
    }

    return lines
        .map((line) => _buildTwoColumnSummaryBulletRow(line, accentColor))
        .toList();
  }

  int _twoColumnLeadExperienceCount(
    int objectiveLineCount,
    int totalExperienceCount,
  ) {
    if (totalExperienceCount <= 2) {
      return totalExperienceCount;
    }

    if (objectiveLineCount >= 12) {
      return 1;
    }
    return 2;
  }

  int _twoColumnLeadEducationCount(int objectiveLineCount) {
    if (objectiveLineCount >= 12) {
      return 0;
    }
    return 1;
  }

  int _twoColumnLeadProjectCount(int objectiveLineCount) {
    if (objectiveLineCount >= 9) {
      return 0;
    }
    return 1;
  }

  pw.Widget _buildTwoColumnSummaryBulletRow(
    String line,
    PdfColor accentColor,
  ) {
    final cleanLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 10,
            height: 10,
            child: pw.CustomPaint(
              painter: (canvas, size) {
                canvas.setFillColor(accentColor);
                canvas.setStrokeColor(accentColor);
                canvas.setLineWidth(0.5);

                canvas.moveTo(1, 2);
                canvas.lineTo(8, 5);
                canvas.lineTo(1, 8);
                canvas.lineTo(1, 2);
                canvas.fillPath();
              },
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              cleanLine,
              style: const pw.TextStyle(
                fontSize: 7.4,
                color: _bodyText,
                lineSpacing: 1.3,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSidebarHeading(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _h(title),
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  pw.Widget _buildSidebarBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(text),
            style: const pw.TextStyle(
              fontSize: 7,
              color: _bodyText,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSidebarText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _sanitizePdfText(text),
        style: const pw.TextStyle(
          fontSize: 7,
          color: _bodyText,
          lineSpacing: 1.2,
        ),
      ),
    );
  }

  pw.Widget _buildMainSectionTitle(String title, PdfColor accentColor) {
    return _buildRightBarSectionHeader(
      title,
      textColor: accentColor,
      dividerColor: PdfColor(
        accentColor.red,
        accentColor.green,
        accentColor.blue,
        0.28,
      ),
      fontSize: 9.2,
      letterSpacing: 0.8,
      marginBottom: 8,
      titleBottomSpacing: 3,
      barWidth: 3,
      barHeight: 10,
    );
  }
}

class MinimalTemplate extends PdfTemplate {
  static const PdfColor _pageBg = PdfColor.fromInt(0xFFF1F2F4);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2E3137);
  static const PdfColor _muted = PdfColor.fromInt(0xFF656B74);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
          buildBackground: (context) => pw.Container(color: _pageBg),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(26, 24, 26, 26),
            decoration: const pw.BoxDecoration(color: _paper),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 154,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.personalInfo.phone.isNotEmpty)
                            _buildContactIconRow(
                              'phone',
                              resume.personalInfo.phone,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                          if (resume.personalInfo.email.isNotEmpty)
                            _buildContactIconRow(
                              'email',
                              resume.personalInfo.email,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                          if (resume.personalInfo.address.isNotEmpty)
                            _buildContactIconRow(
                              'location',
                              resume.personalInfo.address,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.website ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'website',
                              resume.personalInfo.website!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'linkedin',
                              resume.personalInfo.linkedIn!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                          if ((resume.personalInfo.github ?? '').isNotEmpty)
                            _buildContactIconRow(
                              'website',
                              resume.personalInfo.github!,
                              PdfColors.grey700,
                              iconFg: PdfColors.white,
                              textColor: _muted,
                              textSize: 7.3,
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            _sanitizePdfText(
                              resume.personalInfo.fullName.isEmpty
                                  ? 'Your Name'
                                  : resume.personalInfo.fullName,
                            ).toUpperCase(),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 24,
                              color: const PdfColor.fromInt(0xFF243B53),
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(
                                    fontSize: 10.8, color: _muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                    height: 1, width: double.infinity, color: accentColor),
                if ((resume.objective ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  _buildMinimalSectionHeader(
                      'PROFESSIONAL SUMMARY', accentColor),
                  ..._buildSummaryBullets(resume.objective!, accentColor),
                  pw.SizedBox(height: 18),
                ],
                if (resume.experience.isNotEmpty) ...[
                  _buildMinimalSectionHeader('EXPERIENCE', accentColor),
                  ...resume.experience.map(
                    (exp) => _buildMinimalExperience(exp, accentColor),
                  ),
                ],
                if (resume.education.isNotEmpty) ...[
                  _buildMinimalSectionHeader('EDUCATION', accentColor),
                  ...resume.education.map(
                    (edu) => _buildMinimalEducation(edu, accentColor),
                  ),
                ],
                if (resume.skills.isNotEmpty) ...[
                  _buildMinimalSectionHeader('SKILLS', accentColor),
                  pw.Text(
                    resume.skills
                        .map((skill) => _sanitizePdfText(skill.name))
                        .join(' / '),
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: _ink,
                      lineSpacing: 1.45,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                ],
                if (resume.projects.isNotEmpty) ...[
                  _buildMinimalSectionHeader('PROJECTS', accentColor),
                  ...resume.projects.map(
                    (project) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(project.title),
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (project.description.isNotEmpty)
                            pw.Text(
                              _sanitizePdfText(project.description),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: _muted,
                                lineSpacing: 1.35,
                              ),
                              textAlign: pw.TextAlign.justify,
                            ),
                          if (project.technologies.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                project.technologies
                                    .map(_sanitizePdfText)
                                    .join(', '),
                                style: const pw.TextStyle(
                                    fontSize: 8.5, color: _ink),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (resume.certifications.isNotEmpty) ...[
                  _buildMinimalSectionHeader('CERTIFICATIONS', accentColor),
                  ...resume.certifications.map(
                    (cert) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(
                        '${_sanitizePdfText(cert.name)}${cert.issuer.isNotEmpty ? ' - ${_sanitizePdfText(cert.issuer)}' : ''}',
                        style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
                if (resume.languages.isNotEmpty) ...[
                  _buildMinimalSectionHeader('LANGUAGES', accentColor),
                  pw.Text(
                    resume.languages
                        .map(
                          (lang) =>
                              '${_sanitizePdfText(lang.name)} (${_sanitizePdfText(lang.proficiency)})',
                        )
                        .join(', '),
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: _muted,
                      lineSpacing: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildMinimalSectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      child: _buildRightBarSectionHeader(
        title,
        textColor: accentColor,
        dividerColor: PdfColor(
          accentColor.red,
          accentColor.green,
          accentColor.blue,
          0.32,
        ),
        fontSize: 11,
        letterSpacing: 0.7,
        marginBottom: 10,
        titleBottomSpacing: 4,
        barHeight: 11,
      ),
    );
  }

  pw.Widget _buildMinimalExperience(Experience exp, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${_sanitizePdfText(exp.position)} - ${_sanitizePdfText(exp.company)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                  style: const pw.TextStyle(fontSize: 8.6, color: _muted),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          if ((exp.location ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                _sanitizePdfText(exp.location!),
                style: pw.TextStyle(fontSize: 8.5, color: accentColor),
              ),
            ),
          if (_collectExperienceLines(exp).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._buildExperienceLineWidgets(exp, accentColor),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildMinimalEducation(Education edu, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${_sanitizePdfText(edu.degree.isEmpty ? edu.fieldOfStudy : edu.degree)} - ${_sanitizePdfText(edu.institution)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((edu.location ?? '').isNotEmpty)
                  pw.Text(
                    _sanitizePdfText(edu.location!),
                    style: pw.TextStyle(fontSize: 8.5, color: accentColor),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '${DateFormat('yyyy').format(edu.startDate)} - ${edu.isCurrentlyStudying ? _present() : DateFormat('yyyy').format(edu.endDate ?? edu.startDate)}',
              style: const pw.TextStyle(fontSize: 8.6, color: _muted),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pink Rosé Modern template with restrained luxury styling and ATS-friendly hierarchy.
class ElegantPinkTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    return PinkRoseModernPdfTemplate().generate(resume, accentColor);
  }
}

class MulticolorTemplate extends PdfTemplate {
  static const PdfColor _violet = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor _pink = PdfColor.fromInt(0xFFEC4899);
  static const PdfColor _amber = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor _emerald = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF1a1a1a);
  static const PdfColor _grayText = PdfColor.fromInt(0xFF666666);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 42),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (resume.personalInfo.fullName.isEmpty
                              ? 'YOUR NAME'
                              : resume.personalInfo.fullName)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkText,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        resume.personalInfo.jobTitle!.toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _violet,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (resume.personalInfo.email.isNotEmpty)
                    _contactLine(resume.personalInfo.email),
                  if (resume.personalInfo.phone.isNotEmpty)
                    _contactLine(resume.personalInfo.phone),
                  if (resume.personalInfo.address.isNotEmpty)
                    _contactLine(resume.personalInfo.address),
                  if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.linkedIn!),
                  if (resume.personalInfo.github?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.github!),
                  if (resume.personalInfo.website?.isNotEmpty ?? false)
                    _contactLine(resume.personalInfo.website!),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: pw.Container(height: 2, color: accentColor)),
            pw.Expanded(child: pw.Container(height: 2, color: _pink)),
            pw.Expanded(child: pw.Container(height: 2, color: _amber)),
            pw.Expanded(child: pw.Container(height: 2, color: _emerald)),
          ]),
          pw.SizedBox(height: 16),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _sectionHeader('PROFILE', accentColor),
            pw.SizedBox(height: 6),
            ..._multicolorProfileBullets(resume.objective!, accentColor),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _sectionHeader('EXPERIENCE', _pink),
            pw.SizedBox(height: 6),
            ...resume.experience.map((exp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              (exp.location != null && exp.location!.isNotEmpty)
                                  ? '${exp.company.toUpperCase()} - ${exp.location!.toUpperCase()}'
                                  : exp.company.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${DateFormat('MMMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMMM yyyy').format(exp.endDate!)}',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: _grayText),
                          ),
                        ],
                      ),
                      pw.Text(
                        exp.position,
                        style:
                            const pw.TextStyle(fontSize: 9.5, color: _grayText),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        ..._buildSummaryBullets(
                          exp.description,
                          _pink,
                          textAlign: pw.TextAlign.justify,
                        ),
                      ],
                    ],
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.education.isNotEmpty) ...[
            _sectionHeader('EDUCATION', _amber),
            pw.SizedBox(height: 6),
            ...resume.education.map((edu) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        edu.institution.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      pw.Text(
                        edu.fieldOfStudy.isNotEmpty
                            ? '${edu.degree} of ${edu.fieldOfStudy}'
                            : edu.degree,
                        style:
                            const pw.TextStyle(fontSize: 9.5, color: _grayText),
                      ),
                      pw.Text(
                        DateFormat('yyyy').format(edu.endDate ?? edu.startDate),
                        style:
                            const pw.TextStyle(fontSize: 8.6, color: _grayText),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.skills.isNotEmpty) ...[
            _sectionHeader('SKILLS', _emerald),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  resume.skills.take(12).toList().asMap().entries.map((entry) {
                final colors = [_violet, _pink, _amber, _emerald];
                final color = colors[entry.key % colors.length];
                return pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: color.shade(0.12),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    entry.value.name,
                    style: pw.TextStyle(fontSize: 8.5, color: color),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 12),
          ],
          if (resume.projects.isNotEmpty) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.NewPage(
                  freeSpace: 90 + (resume.projects.length * 20),
                ),
                _sectionHeader('PROJECTS', _violet),
                pw.SizedBox(height: 6),
                ...resume.projects.map((proj) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(proj.title),
                            style: pw.TextStyle(
                              fontSize: 9.8,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          if (proj.description.isNotEmpty)
                            pw.Text(
                              _sanitizePdfText(proj.description),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                lineSpacing: 1.45,
                                color: _grayText,
                              ),
                              textAlign: pw.TextAlign.justify,
                            ),
                          if (proj.url?.isNotEmpty ?? false)
                            pw.Text(
                              _sanitizePdfText(proj.url!),
                              style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: _violet,
                                decoration: pw.TextDecoration.underline,
                              ),
                            ),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 4),
              ],
            ),
          ],
          if (resume.languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES', _pink),
            pw.SizedBox(height: 6),
            ...resume.languages.map((lang) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${_sanitizePdfText(lang.name)}${lang.proficiency.isNotEmpty ? ' | ${_sanitizePdfText(lang.proficiency)}' : ''}',
                    style: const pw.TextStyle(fontSize: 9.2, color: _grayText),
                  ),
                )),
            pw.SizedBox(height: 4),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS', _amber),
            pw.SizedBox(height: 6),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _multicolorArrowMarker(_amber),
                      pw.SizedBox(width: 2),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: _sanitizePdfText(cert.name),
                                style: pw.TextStyle(
                                  fontSize: 9.2,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _darkText,
                                ),
                              ),
                              if (cert.issuer.isNotEmpty)
                                pw.TextSpan(
                                  text: ' - ${_sanitizePdfText(cert.issuer)}',
                                  style: const pw.TextStyle(
                                      fontSize: 9, color: _grayText),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          ...orderedUserCustomSections(resume).expand(
            (section) => _buildGenericUserCustomSectionWidgets(
              section,
              accentColor: accentColor,
              bottomSpacing: 10,
              headerBuilder: (title) =>
                  _sectionHeader(title.toUpperCase(), accentColor),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  List<pw.Widget> _multicolorProfileBullets(
    String text,
    PdfColor bulletColor,
  ) {
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
        .map((line) => line.replaceFirst(RegExp(r'^[-*•➤]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _multicolorArrowMarker(bulletColor),
                pw.SizedBox(width: 2),
                pw.Expanded(
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      lineSpacing: 1.8,
                      color: _grayText,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  pw.Widget _multicolorArrowMarker(PdfColor color) => pw.SizedBox(
        width: 14,
        height: 12,
        child: pw.CustomPaint(
          size: const PdfPoint(14, 12),
          painter: (canvas, size) {
            canvas.setFillColor(color);
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
      );

  pw.Widget _contactLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9, color: _grayText)),
      );

  pw.Widget _sectionHeader(String title, PdfColor color) =>
      _buildRightBarSectionHeader(
        title,
        textColor: color,
        dividerColor: color,
        fontSize: 11,
        letterSpacing: 1.0,
        marginBottom: 4,
        titleBottomSpacing: 3,
        lineThickness: 1.5,
        barHeight: 10,
      );
}

// -----------------------------------------------------------------------------
/// FlexColor Sidebar template with an accent rail, floating masthead,
/// and modular sidebar cards.
// -----------------------------------------------------------------------------
class BlueGrayTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    return FlexColorSidebarPdfTemplate().generate(resume, accentColor);
  }
}

/// Factory to get the appropriate template based on templateId
// -----------------------------------------------------------------------------
// Template: Professional
// Original layout: editorial ribbon frame with stacked section cards,
// contact capsules, and modular content blocks.
// -----------------------------------------------------------------------------
class ProfessionalTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    return ProfessionalResumePdfTemplate().generate(resume, accentColor);
  }
}

/// Legacy inline stub – kept so that existing code compiling against
/// [ProfessionalTemplate] still works.  Real logic lives in
/// [ProfessionalResumePdfTemplate].
class _ProfessionalTemplateInline extends PdfTemplate {
  static const PdfColor _paper = PdfColor.fromInt(0xFFF7F8FC);
  static const PdfColor _card = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _ink = PdfColor.fromInt(0xFF243041);
  static const PdfColor _muted = PdfColor.fromInt(0xFF667085);
  static const PdfColor _line = PdfColor.fromInt(0xFFD9E2EC);
  static const PdfColor _soft = PdfColor.fromInt(0xFFEEF3F8);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final softAccent = _scalePdfColor(accentColor, 1.0, 0.10);
    final edgeAccent = _scalePdfColor(accentColor, 1.0, 0.22);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 32, 34, 28),
          buildBackground: (context) {
            final lightAccent = PdfColor(
              accentColor.red * 0.16 + 0.84,
              accentColor.green * 0.16 + 0.84,
              accentColor.blue * 0.16 + 0.84,
            );
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                color: _paper,
                padding: const pw.EdgeInsets.all(18),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      width: 10,
                      decoration: pw.BoxDecoration(
                        color: lightAccent,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: _line, width: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        build: (context) => [
          _buildHeader(resume, accentColor, softAccent, edgeAccent),
          if (resume.objective?.trim().isNotEmpty ?? false) ...[
            _sectionHeader('PROFILE SNAPSHOT', accentColor),
            _summaryCard(resume.objective!, accentColor, softAccent),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _sectionHeader('CAREER EXPERIENCE', accentColor),
            ...resume.experience.map(
              (exp) => _experienceCard(exp, accentColor, softAccent),
            ),
            pw.SizedBox(height: 4),
          ],
          if (resume.skills.isNotEmpty) ...[
            _sectionHeader('CORE SKILLS', accentColor),
            _skillsCard(resume.skills, accentColor, softAccent),
            pw.SizedBox(height: 14),
          ],
          if (resume.projects.isNotEmpty) ...[
            _sectionHeader('SELECTED PROJECTS', accentColor),
            ...resume.projects.map(
              (project) => _projectCard(project, accentColor, softAccent),
            ),
            pw.SizedBox(height: 4),
          ],
          if (resume.education.isNotEmpty) ...[
            _sectionHeader('EDUCATION', accentColor),
            ...resume.education.map(
              (education) => _educationCard(education, accentColor),
            ),
            pw.SizedBox(height: 4),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS', accentColor),
            _stackedListCard(
              resume.certifications
                  .map(
                    (certification) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(certification.name),
                          style: pw.TextStyle(
                            fontSize: 9.6,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        if (certification.issuer.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              _sanitizePdfText(certification.issuer),
                              style: const pw.TextStyle(
                                fontSize: 8.3,
                                color: _muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 4),
          ],
          if (resume.languages.isNotEmpty) ...[
            _sectionHeader('LANGUAGES', accentColor),
            _stackedListCard(
              resume.languages
                  .map(
                    (language) => pw.Text(
                      _sanitizePdfText(
                        '${language.name}${language.proficiency.isNotEmpty ? ' - ${language.proficiency}' : ''}',
                      ),
                      style: const pw.TextStyle(
                        fontSize: 8.8,
                        color: _ink,
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 4),
          ],
          if (resume.references.isNotEmpty) ...[
            _sectionHeader('REFERENCES', accentColor),
            ...resume.references.map(
              (reference) => _referenceCard(reference, accentColor),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(
    ResumeModel resume,
    PdfColor accentColor,
    PdfColor softAccent,
    PdfColor edgeAccent,
  ) {
    final contactItems = <String>[];
    if (resume.personalInfo.email.isNotEmpty) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.email));
    }
    if (resume.personalInfo.phone.isNotEmpty) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.phone));
    }
    if (resume.personalInfo.address.isNotEmpty) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.address));
    }
    if (resume.personalInfo.linkedIn?.isNotEmpty ?? false) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.linkedIn!));
    }
    if (resume.personalInfo.github?.isNotEmpty ?? false) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.github!));
    }
    if (resume.personalInfo.website?.isNotEmpty ?? false) {
      contactItems.add(_sanitizePdfText(resume.personalInfo.website!));
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border(
          top: pw.BorderSide(color: edgeAccent, width: 1.0),
          right: pw.BorderSide(color: edgeAccent, width: 1.0),
          bottom: pw.BorderSide(color: edgeAccent, width: 1.0),
          left: pw.BorderSide(color: accentColor, width: 14),
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                        resume.personalInfo.fullName.trim().isEmpty
                            ? 'YOUR NAME'
                            : _sanitizePdfText(
                                resume.personalInfo.fullName
                                    .trim()
                                    .toUpperCase(),
                              ),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (resume.personalInfo.jobTitle?.isNotEmpty ?? false)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 5),
                          child: pw.Text(
                            _sanitizePdfText(
                              resume.personalInfo.jobTitle!,
                            ),
                            style: pw.TextStyle(
                              fontSize: 10.2,
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (contactItems.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Wrap(
                spacing: 7,
                runSpacing: 7,
                children: contactItems
                    .map(
                      (item) => _contactCapsule(
                        item,
                        accentColor,
                        softAccent,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _contactCapsule(
    String text,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _scalePdfColor(accentColor, 1.0, 0.16)),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8.1, color: _ink),
      ),
    );
  }

  pw.Widget _sectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: _ink,
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
          pw.Expanded(child: pw.Container(height: 1, color: _line)),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 24,
            height: 4,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryCard(
    String text,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    final summaryLines = _summaryLines(text);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border(
          top: const pw.BorderSide(color: _line, width: 0.9),
          right: const pw.BorderSide(color: _line, width: 0.9),
          bottom: const pw.BorderSide(color: _line, width: 0.9),
          left: pw.BorderSide(color: accentColor, width: 8),
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: summaryLines.isNotEmpty
              ? summaryLines
                  .map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 5,
                            height: 5,
                            margin: const pw.EdgeInsets.only(top: 4, right: 7),
                            color: accentColor,
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              line,
                              style: const pw.TextStyle(
                                fontSize: 9.2,
                                color: _ink,
                                lineSpacing: 1.45,
                              ),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList()
              : [
                  pw.Text(
                    _sanitizePdfText(text),
                    style: const pw.TextStyle(
                      fontSize: 9.2,
                      color: _ink,
                      lineSpacing: 1.55,
                    ),
                    textAlign: pw.TextAlign.left,
                  ),
                ],
        ),
      ),
    );
  }

  pw.Widget _experienceCard(
    Experience exp,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    final dateLabel = _dateRange(
      exp.startDate,
      exp.endDate,
      exp.isCurrentlyWorking,
      'MMM yyyy',
    );
    final detailLines = _collectExperienceLines(exp);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
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
                      _sanitizePdfText(exp.position),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      _sanitizePdfText(exp.company),
                      style: pw.TextStyle(
                        fontSize: 8.8,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (exp.location?.isNotEmpty ?? false)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _sanitizePdfText(exp.location),
                          style: const pw.TextStyle(
                            fontSize: 8.0,
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
                color: softAccent,
                child: pw.Text(
                  dateLabel,
                  style: pw.TextStyle(
                    fontSize: 7.8,
                    color: accentColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            ...detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      margin: const pw.EdgeInsets.only(top: 4, right: 6),
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _sanitizePdfText(line),
                        style: const pw.TextStyle(
                          fontSize: 8.8,
                          color: _ink,
                          lineSpacing: 1.45,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _skillsCard(
    List<Skill> skills,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.take(12).map((skill) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _card,
              border: pw.Border.all(
                color: _scalePdfColor(accentColor, 1.0, 0.18),
                width: 0.8,
              ),
            ),
            child: pw.Text(
              _sanitizePdfText(skill.name),
              style: const pw.TextStyle(fontSize: 8.3, color: _ink),
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _projectCard(
    Project project,
    PdfColor accentColor,
    PdfColor softAccent,
  ) {
    final stackText = project.technologies.isNotEmpty
        ? project.technologies.map(_sanitizePdfText).join(' • ')
        : '';
    final projectUrl = _sanitizePdfText(project.url).trim();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
              fontSize: 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (project.description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                _sanitizePdfText(project.description),
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _ink,
                  lineSpacing: 1.45,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          if (projectUrl.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                projectUrl,
                style: pw.TextStyle(
                  fontSize: 8.1,
                  color: accentColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          if (stackText.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                color: softAccent,
                child: pw.Text(
                  stackText,
                  style: pw.TextStyle(
                    fontSize: 7.8,
                    color: accentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _summaryLines(String text) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-*▪■•]+\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isNotEmpty) {
      return lines;
    }

    return normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-*▪■•]+\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  pw.Widget _educationCard(Education education, PdfColor accentColor) {
    final dateLabel = _dateRange(
      education.startDate,
      education.endDate,
      education.isCurrentlyStudying,
      'yyyy',
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(education.degree),
                  style: pw.TextStyle(
                    fontSize: 10.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    _sanitizePdfText(education.institution),
                    style: pw.TextStyle(
                      fontSize: 8.8,
                      color: accentColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (education.grade?.isNotEmpty ?? false)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      'Grade: ${_sanitizePdfText(education.grade!)}',
                      style: const pw.TextStyle(
                        fontSize: 8.0,
                        color: _muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            dateLabel,
            style: const pw.TextStyle(fontSize: 8.2, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _referenceCard(Reference reference, PdfColor accentColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Column(
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
              _sanitizePdfText('${reference.position} | ${reference.company}'),
              style: pw.TextStyle(
                fontSize: 8.6,
                color: accentColor,
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
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: pw.BoxDecoration(
        color: _card,
        border: pw.Border.all(color: _line, width: 0.9),
      ),
      child: pw.Column(
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
            .toList(),
      ),
    );
  }

  String _dateRange(
    DateTime startDate,
    DateTime? endDate,
    bool isCurrent,
    String pattern,
  ) {
    final start = DateFormat(pattern).format(startDate);
    final end = isCurrent
        ? _present()
        : DateFormat(pattern).format(endDate ?? startDate);
    return '$start - $end';
  }
}

// -----------------------------------------------------------------------------
// Template: Modern
// Inspired by: White Grey Gold Aesthetic Professional CV (Canva EAFeIrrycrE)
// Layout: Single column, gold dividers, elegant centred header, cream tone
// -----------------------------------------------------------------------------
class ModernAestheticTemplate extends PdfTemplate {
  static const PdfColor _darkBrown = PdfColor(0.384, 0.345, 0.337);
  static const PdfColor _muted = PdfColor.fromInt(0xFF777777);
  static const PdfColor _line = PdfColor.fromInt(0xFFE2DED8);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    final email = _sanitizePdfText(resume.personalInfo.email).trim();
    final secondaryContacts = <String>[
      if (resume.personalInfo.phone.isNotEmpty)
        _sanitizePdfText(resume.personalInfo.phone),
      if (resume.personalInfo.address.isNotEmpty)
        _sanitizePdfText(resume.personalInfo.address),
      if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
        _sanitizePdfText(resume.personalInfo.linkedIn!),
      if ((resume.personalInfo.github ?? '').isNotEmpty)
        _sanitizePdfText(resume.personalInfo.github!),
      if ((resume.personalInfo.website ?? '').isNotEmpty)
        _sanitizePdfText(resume.personalInfo.website!),
    ];
    final skillFill = _blendPdfWithWhite(accentColor, 0.12);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 40),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  resume.personalInfo.fullName.trim().isEmpty
                      ? 'YOUR NAME'
                      : _sanitizePdfText(
                          resume.personalInfo.fullName.trim().toUpperCase(),
                        ),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkBrown,
                    letterSpacing: 2.2,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (resume.personalInfo.jobTitle?.trim().isNotEmpty ??
                    false) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(resume.personalInfo.jobTitle!),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                        child: pw.Container(height: 0.8, color: accentColor)),
                    pw.SizedBox(width: 8),
                    pw.Flexible(
                      child: pw.Text(
                        email.isEmpty ? 'email@example.com' : email,
                        style: const pw.TextStyle(
                          fontSize: 8.8,
                          color: _muted,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                        child: pw.Container(height: 0.8, color: accentColor)),
                  ],
                ),
                if (secondaryContacts.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    secondaryContacts.join('  •  '),
                    style: const pw.TextStyle(
                      fontSize: 7.8,
                      color: _muted,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: accentColor),
          if (resume.objective?.isNotEmpty ?? false) ...[
            pw.SizedBox(height: 10),
            _maSection('SUMMARY', accentColor),
            ..._maBullets(_splitPdfLines(resume.objective), accentColor),
          ],
          if (resume.experience.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('EXPERIENCE', accentColor),
            ...resume.experience.map(
              (exp) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _maExperience(exp, accentColor),
              ),
            ),
          ],
          if (resume.education.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('EDUCATION', accentColor),
            ...resume.education.map(
              (edu) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: _maEducation(edu),
              ),
            ),
          ],
          if (resume.skills.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('SKILLS', accentColor),
            pw.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: resume.skills
                  .map(
                    (skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: skillFill,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        _sanitizePdfText(skill.name),
                        style: pw.TextStyle(
                          fontSize: 8.6,
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (resume.projects.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('PROJECTS', accentColor),
            ...resume.projects.map(
              (project) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _maProject(project, accentColor),
              ),
            ),
          ],
          if (resume.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('CERTIFICATIONS', accentColor),
            ...resume.certifications.map(
              (cert) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  cert.issuer.isNotEmpty
                      ? '${_sanitizePdfText(cert.name)} - ${_sanitizePdfText(cert.issuer)}'
                      : _sanitizePdfText(cert.name),
                  style: const pw.TextStyle(
                    fontSize: 8.9,
                    color: _muted,
                  ),
                ),
              ),
            ),
          ],
          if (resume.languages.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _maSection('LANGUAGES', accentColor),
            ...resume.languages.map(
              (language) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  language.proficiency.isNotEmpty
                      ? '${_sanitizePdfText(language.name)} (${_sanitizePdfText(language.proficiency)})'
                      : _sanitizePdfText(language.name),
                  style: const pw.TextStyle(
                    fontSize: 8.9,
                    color: _muted,
                  ),
                ),
              ),
            ),
          ],
          ...orderedUserCustomSections(resume)
              .where((section) => section.items.isNotEmpty)
              .expand(
                (section) => [
                  pw.SizedBox(height: 8),
                  _maCustomSection(section, accentColor),
                ],
              ),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _maSection(String title, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _h(title),
            style: pw.TextStyle(
              fontSize: 11.2,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
              height: 0.9, color: _blendPdfWithWhite(accentColor, 0.28)),
        ],
      ),
    );
  }

  List<pw.Widget> _maBullets(List<String> lines, PdfColor accentColor) {
    return lines
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: pw.TextStyle(
                    fontSize: 9.0,
                    color: accentColor,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    _sanitizePdfText(line),
                    style: const pw.TextStyle(
                      fontSize: 9.0,
                      color: _muted,
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

  pw.Widget _maExperience(Experience exp, PdfColor accentColor) {
    final metaParts = <String>[
      if (exp.company.trim().isNotEmpty) _sanitizePdfText(exp.company.trim()),
      '${exp.startDate.year} - ${exp.isCurrentlyWorking ? _present() : (exp.endDate?.year.toString() ?? _present())}',
      if ((exp.location ?? '').trim().isNotEmpty)
        _sanitizePdfText(exp.location!.trim()),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(exp.position),
          style: pw.TextStyle(
            fontSize: 11.2,
            fontWeight: pw.FontWeight.bold,
            color: _darkBrown,
          ),
        ),
        pw.Text(
          metaParts.join('  •  '),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _muted,
          ),
        ),
        pw.SizedBox(height: 3),
        ..._maBullets(_descriptionFirstExperienceLines(exp), accentColor),
      ],
    );
  }

  pw.Widget _maEducation(Education education) {
    final metaParts = <String>[
      if (education.institution.trim().isNotEmpty)
        _sanitizePdfText(education.institution.trim()),
      '${education.startDate.year} - ${education.isCurrentlyStudying ? _present() : (education.endDate?.year.toString() ?? education.startDate.year.toString())}',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(
            education.degree.isNotEmpty
                ? education.degree
                : education.fieldOfStudy,
          ),
          style: pw.TextStyle(
            fontSize: 10.8,
            fontWeight: pw.FontWeight.bold,
            color: _darkBrown,
          ),
        ),
        pw.Text(
          metaParts.join('  •  '),
          style: const pw.TextStyle(
            fontSize: 8.8,
            color: _muted,
          ),
        ),
        if (education.grade?.trim().isNotEmpty ?? false)
          pw.Text(
            'Grade: ${_sanitizePdfText(education.grade!)}',
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: _muted,
            ),
          ),
      ],
    );
  }

  pw.Widget _maProject(Project project, PdfColor accentColor) {
    final details = _splitPdfLines(project.description);
    final extraLines = <String>[
      if (project.technologies.isNotEmpty)
        'Technologies: ${project.technologies.map(_sanitizePdfText).join(', ')}',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(project.title),
          style: pw.TextStyle(
            fontSize: 10.4,
            fontWeight: pw.FontWeight.bold,
            color: _darkBrown,
          ),
        ),
        ..._maBullets([...details, ...extraLines], accentColor),
        if ((project.url ?? '').trim().isNotEmpty)
          pw.Text(
            _sanitizePdfText(project.url!.trim()),
            style: pw.TextStyle(
              fontSize: 8.4,
              color: accentColor,
            ),
          ),
      ],
    );
  }

  pw.Widget _maCustomSection(CustomSection section, PdfColor accentColor) {
    final title = normalizeUserCustomSectionTitle(section.title);
    final itemWidgets = section.items.expand((item) {
      final displayItem = buildUserCustomSectionDisplayItem(item);
      final metaParts = <String>[
        if (displayItem.subtitle.isNotEmpty)
          _sanitizePdfText(displayItem.subtitle),
        if (displayItem.date != null)
          DateFormat('MMM yyyy').format(displayItem.date!),
      ];

      if (!displayItem.hasContent) {
        return const <pw.Widget>[];
      }

      return <pw.Widget>[
        if (displayItem.heading.isNotEmpty)
          pw.Text(
            _sanitizePdfText(displayItem.heading),
            style: pw.TextStyle(
              fontSize: 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _darkBrown,
            ),
          ),
        if (metaParts.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
            child: pw.Text(
              metaParts.join('  •  '),
              style: const pw.TextStyle(
                fontSize: 8.8,
                color: _muted,
              ),
            ),
          ),
        ..._maBullets(displayItem.detailLines, accentColor),
        pw.SizedBox(height: 4),
      ];
    }).toList(growable: false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _maSection(title.isEmpty ? 'CUSTOM SECTION' : title.toUpperCase(), accentColor),
        ...itemWidgets,
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Template: Classic
// Inspired by: Green & Black Corporate ATS Resume (Canva EAGdmNIe5UE)
// Layout: ATS-friendly, dark header bar, two-col skills grid, cream tone
// -----------------------------------------------------------------------------
class ClassicAtsTemplate extends PdfTemplate {
  static const PdfColor _headerBg = PdfColor(0.098, 0.098, 0.098); // near-black
  static const PdfColor _cream = PdfColor(0.973, 0.969, 0.949); // #F8F7F2
  static const PdfColor _darkBrown = PdfColor(0.384, 0.345, 0.337);
  static const PdfColor _navyDark = PdfColor.fromInt(0xFF1e2d3d);
  static const PdfColor _bodyText = PdfColor(0.12, 0.12, 0.12);
  static const PdfColor _midGray = PdfColor(0.494, 0.494, 0.494);
  static const PdfColor _lightGray = PdfColor(0.890, 0.890, 0.890);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => [
        // -- Full-width dark header ----------------------------------------
        pw.Container(
          width: double.infinity,
          color: _headerBg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 26),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resume.personalInfo.fullName.isEmpty
                      ? 'YOUR NAME'
                      : resume.personalInfo.fullName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 2),
                ),
                if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(resume.personalInfo.jobTitle!,
                      style: pw.TextStyle(
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold)),
                ],
                pw.SizedBox(height: 12),
                // Contact row inline
                pw.Wrap(
                  spacing: 18,
                  runSpacing: 5,
                  children: [
                    if (resume.personalInfo.email.isNotEmpty)
                      _headerContact(
                          'email', resume.personalInfo.email, accentColor),
                    if (resume.personalInfo.phone.isNotEmpty)
                      _headerContact(
                          'phone', resume.personalInfo.phone, accentColor),
                    if (resume.personalInfo.address.isNotEmpty)
                      _headerContact(
                          'location', resume.personalInfo.address, accentColor),
                    if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                      _headerContact('linkedin', resume.personalInfo.linkedIn!,
                          accentColor),
                    if (resume.personalInfo.website?.isNotEmpty ?? false)
                      _headerContact(
                          'website', resume.personalInfo.website!, accentColor),
                  ],
                ),
              ]),
        ),

        // -- Body ---------------------------------------------------------
        pw.Container(
          color: _cream,
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary
                if (resume.objective?.isNotEmpty ?? false) ...[
                  _atsSection('PROFESSIONAL SUMMARY', accentColor),
                  pw.Text(_sanitizePdfText(resume.objective!),
                      style: const pw.TextStyle(
                          fontSize: 9.5,
                          lineSpacing: 1.8,
                          color: PdfColors.grey800),
                      textAlign: pw.TextAlign.justify),
                  pw.SizedBox(height: 16),
                ],

                // Experience
                if (resume.experience.isNotEmpty) ...[
                  _atsSection('WORK EXPERIENCE', accentColor),
                  ...resume.experience.map((exp) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 14),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                        child: pw.Text(exp.position,
                                            style: pw.TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.grey900))),
                                    pw.Text(
                                      '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                                      style: const pw.TextStyle(
                                          fontSize: 8.5, color: _midGray),
                                    ),
                                  ]),
                              pw.Text(
                                '${exp.company}${(exp.location?.isNotEmpty ?? false) ? '  |  ${exp.location}' : ''}',
                                style: pw.TextStyle(
                                    fontSize: 9.5,
                                    color: accentColor,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              if (exp.achievements.isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                ...exp.achievements.map((r) => pw.Padding(
                                      padding:
                                          const pw.EdgeInsets.only(bottom: 2),
                                      child: pw.Row(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text('- ',
                                                style: const pw.TextStyle(
                                                    fontSize: 9,
                                                    color: _midGray)),
                                            pw.Expanded(
                                                child: pw.Text(
                                                    _sanitizePdfText(r),
                                                    style: const pw.TextStyle(
                                                        fontSize: 9,
                                                        lineSpacing: 1.4),
                                                    textAlign:
                                                        pw.TextAlign.justify)),
                                          ]),
                                    )),
                              ],
                            ]),
                      )),
                ],

                // Education
                if (resume.education.isNotEmpty) ...[
                  _atsSection('EDUCATION', accentColor),
                  ...resume.education.map((edu) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                        child: pw.Text(edu.degree,
                                            style: pw.TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.grey900))),
                                    pw.Text(
                                        DateFormat('yyyy').format(
                                            edu.endDate ?? edu.startDate),
                                        style: const pw.TextStyle(
                                            fontSize: 9, color: _midGray)),
                                  ]),
                              pw.Text(edu.institution,
                                  style: pw.TextStyle(
                                      fontSize: 9.5, color: accentColor)),
                              if (edu.grade?.isNotEmpty ?? false)
                                pw.Text('Grade: ${edu.grade}',
                                    style: const pw.TextStyle(
                                        fontSize: 9, color: _midGray)),
                            ]),
                      )),
                ],

                // Skills ? two column grid
                if (resume.skills.isNotEmpty) ...[
                  _atsSection('SKILLS', accentColor),
                  pw.Table(
                    columnWidths: const {
                      0: pw.FlexColumnWidth(),
                      1: pw.FlexColumnWidth()
                    },
                    children: _twoColSkills(resume.skills, accentColor),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Projects
                if (resume.projects.isNotEmpty) ...[
                  _atsSection('PROJECTS', accentColor),
                  ...resume.projects.map((proj) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(proj.title,
                                  style: pw.TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _darkBrown)),
                              if (proj.description.isNotEmpty)
                                pw.Text(_sanitizePdfText(proj.description),
                                    style: const pw.TextStyle(
                                        fontSize: 9, lineSpacing: 1.4),
                                    textAlign: pw.TextAlign.justify),
                              if (proj.technologies.isNotEmpty)
                                pw.Text(
                                    'Stack: ${proj.technologies.join(", ")}',
                                    style: pw.TextStyle(
                                        fontSize: 9, color: accentColor)),
                            ]),
                      )),
                ],

                // Certifications
                if (resume.certifications.isNotEmpty) ...[
                  _atsSection('CERTIFICATIONS', accentColor),
                  ...resume.certifications.map((cert) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(cert.name,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _darkBrown)),
                              pw.Text(cert.issuer,
                                  style: const pw.TextStyle(
                                      fontSize: 9, color: _midGray)),
                            ]),
                      )),
                ],

                // Languages
                if (resume.languages.isNotEmpty) ...[
                  _atsSection('LANGUAGES', accentColor),
                  pw.Text(
                    resume.languages
                        .map((l) => '${l.name} (${l.proficiency})')
                        .join('  |  '),
                    style: const pw.TextStyle(fontSize: 9.5, color: _darkBrown),
                  ),
                ],
              ]),
        ),
      ],
    ));
    return pdf;
  }

  pw.Widget _atsSection(String title, PdfColor ac) =>
      _buildRightBarSectionHeader(
        title,
        textColor: _darkBrown,
        dividerColor: _lightGray,
        barColor: ac,
        fontSize: 11,
        letterSpacing: 1.0,
        marginBottom: 10,
        titleBottomSpacing: 3,
        lineThickness: 1.5,
        barHeight: 10,
      );

  pw.Widget _headerContact(String icon, String text, PdfColor iconColor) =>
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 11,
            height: 11,
            child: pw.CustomPaint(
              size: const PdfPoint(11, 11),
              painter: (canvas, size) {
                final cx = size.x / 2;
                final cy = size.y / 2;
                canvas.setFillColor(iconColor);
                canvas.drawEllipse(cx, cy, cx, cy);
                canvas.fillPath();
                _drawPdfIcon(canvas, icon, cx, cy, cx * 0.52, _navyDark);
              },
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(text,
              style: const pw.TextStyle(fontSize: 8, color: _bodyText)),
        ],
      );

  List<pw.TableRow> _twoColSkills(List<Skill> skills, PdfColor ac) {
    final rows = <pw.TableRow>[];
    for (var i = 0; i < skills.length; i += 2) {
      rows.add(pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5, right: 10),
          child: pw.Row(children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(right: 6, top: 4),
              width: 4,
              height: 4,
              decoration:
                  pw.BoxDecoration(color: ac, shape: pw.BoxShape.circle),
            ),
            pw.Expanded(
                child: pw.Text(skills[i].name,
                    style: const pw.TextStyle(fontSize: 9.5))),
          ]),
        ),
        i + 1 < skills.length
            ? pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(right: 6, top: 4),
                    width: 4,
                    height: 4,
                    decoration:
                        pw.BoxDecoration(color: ac, shape: pw.BoxShape.circle),
                  ),
                  pw.Expanded(
                      child: pw.Text(skills[i + 1].name,
                          style: const pw.TextStyle(fontSize: 9.5))),
                ]),
              )
            : pw.SizedBox(),
      ]));
    }
    return rows;
  }
}

// -----------------------------------------------------------------------------
// Template: Classic 2
// -----------------------------------------------------------------------------
class AtsOptimizedCleanTemplate extends PdfTemplate {
  static const PdfColor _nearBlack = PdfColor.fromInt(0xFF111111);
  static const PdfColor _bodyText = PdfColor.fromInt(0xFF374151);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _lineGray = PdfColor.fromInt(0xFFE5E7EB);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final aboutSegments = _atsCleanSegments(resume.objective);
    final leadAboutSegments = aboutSegments.take(2).toList(growable: false);
    final overflowAboutSegments = aboutSegments.skip(2).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (resume.personalInfo.fullName.isEmpty
                              ? 'YOUR NAME'
                              : _sanitizePdfText(resume.personalInfo.fullName))
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 23,
                        fontWeight: pw.FontWeight.bold,
                        color: _nearBlack,
                        letterSpacing: 1.4,
                      ),
                    ),
                    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                      pw.Text(
                        _sanitizePdfText(resume.personalInfo.jobTitle!),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (resume.personalInfo.phone.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                    if (resume.personalInfo.email.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.email),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                    if (resume.personalInfo.address.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.address),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                    if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.linkedIn!),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                    if ((resume.personalInfo.github ?? '').isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.github!),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                    if ((resume.personalInfo.website ?? '').isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.website!),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _bodyText)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1.8, color: accentColor),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(_h('ABOUT ME'),
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    if (leadAboutSegments.isNotEmpty)
                      ..._atsCleanBulletsFromSegments(
                          leadAboutSegments, accentColor)
                    else
                      pw.Text(
                        'A motivated professional with specialist expertise in engineering and project delivery.',
                        style: const pw.TextStyle(
                            fontSize: 9.2, color: _bodyText, lineSpacing: 1.45),
                      ),
                  ],
                ),
              ),
              if (resume.skills.isNotEmpty) ...[
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Core Skills',
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor)),
                      pw.SizedBox(height: 4),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: resume.skills
                            .take(6)
                            .map((skill) => pw.Text(
                                  _sanitizePdfText(skill.name),
                                  style: const pw.TextStyle(
                                      fontSize: 8.8, color: _bodyText),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (overflowAboutSegments.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            ..._atsCleanBulletsFromSegments(overflowAboutSegments, accentColor),
          ],
          pw.SizedBox(height: 10),
          pw.Container(height: 0.8, color: _lineGray),
          pw.SizedBox(height: 10),
          if (resume.experience.isNotEmpty) ...[
            _atsSimpleSection('EXPERIENCE', accentColor),
            ...resume.experience.take(3).map((exp) {
              final start = DateFormat('MMM yyyy').format(exp.startDate);
              final end = exp.isCurrentlyWorking
                  ? _present()
                  : DateFormat('MMM yyyy').format(exp.endDate!);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(_sanitizePdfText(exp.position),
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _nearBlack)),
                        ),
                        pw.Text('$start – $end',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: _mutedText)),
                      ],
                    ),
                    pw.Text(_sanitizePdfText(exp.company),
                        style:
                            const pw.TextStyle(fontSize: 9, color: _bodyText)),
                    if (exp.achievements.isNotEmpty)
                      ..._buildSummaryBullets(
                          exp.achievements.take(3).join('\n'), accentColor)
                    else if (exp.description.isNotEmpty)
                      ..._buildSummaryBullets(exp.description, accentColor),
                  ],
                ),
              );
            }),
          ],
          if (resume.education.isNotEmpty) ...[
            _atsSimpleSection('EDUCATION', accentColor),
            ...resume.education.take(3).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Container(
                    width: double.infinity,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(_sanitizePdfText(edu.degree),
                            style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _nearBlack)),
                        pw.Text(_sanitizePdfText(edu.institution),
                            style: const pw.TextStyle(
                                fontSize: 8.8, color: _bodyText)),
                        pw.Text(
                          DateFormat('yyyy')
                              .format(edu.endDate ?? edu.startDate),
                          style: const pw.TextStyle(
                              fontSize: 8.2, color: _mutedText),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          if (resume.skills.isNotEmpty) ...[
            _atsSimpleSection('SKILLS', accentColor),
            pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: resume.skills
                  .map((skill) => pw.Text(
                        _sanitizePdfText(skill.name),
                        style:
                            const pw.TextStyle(fontSize: 8.8, color: _bodyText),
                      ))
                  .toList(),
            ),
            pw.SizedBox(height: 8),
          ],
          if (resume.projects.isNotEmpty) ...[
            _atsSimpleSection('PROJECTS', accentColor),
            ...resume.projects.take(4).map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _nearBlack)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: _bodyText,
                                lineSpacing: 1.35)),
                      if ((project.url ?? '').isNotEmpty)
                        pw.Text(_sanitizePdfText(project.url!),
                            style: pw.TextStyle(
                                fontSize: 8.5,
                                color: accentColor,
                                decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                )),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _atsSimpleSection('CERTIFICATIONS', accentColor),
            ...resume.certifications.take(4).map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(fontSize: 9, color: accentColor)),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: _sanitizePdfText(cert.name),
                                style: pw.TextStyle(
                                    fontSize: 8.9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _nearBlack),
                              ),
                              if (cert.issuer.isNotEmpty)
                                pw.TextSpan(
                                  text: ' - ${_sanitizePdfText(cert.issuer)}',
                                  style: const pw.TextStyle(
                                      fontSize: 8.8, color: _bodyText),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _atsSimpleSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(_h(title),
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
                letterSpacing: 1.0)),
      );

  List<String> _atsCleanSegments(String? text) {
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
        .map((line) => line.replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<pw.Widget> _atsCleanBulletsFromSegments(
    List<String> segments,
    PdfColor accentColor,
  ) {
    return segments
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 11,
                  child: pw.CustomPaint(
                    size: const PdfPoint(11, 11),
                    painter: (canvas, size) {
                      canvas.setFillColor(accentColor);
                      canvas.drawEllipse(5.5, 5.5, 2.1, 2.1);
                      canvas.fillPath();
                    },
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(
                        fontSize: 9.2, color: _bodyText, lineSpacing: 1.45),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Template: Education Resume
// Inspired by: Dark Blue and White Minimalist Education Resume (Canva EAGGoKggvyA)
// Layout: Full-width dark navy header, white single-column body, cream accents
// -----------------------------------------------------------------------------
class CoolBlueTemplate extends PdfTemplate {
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) {
    return VividProResumePdfTemplate().generate(resume, accentColor);
  }
}

// -----------------------------------------------------------------------------
// Template: Professional Accountant
// Inspired by: White and Black Minimalist Professional Accountant Resume (EAGoCwgVkoQ)
// Layout: Near-black header, white body, two-column skills/certifications grid
// -----------------------------------------------------------------------------
class ProfessionalAccountantTemplate extends PdfTemplate {
  static const PdfColor _nearBlack = PdfColor.fromInt(0xFF242527);
  static const PdfColor _darkGray = PdfColor.fromInt(0xFF5B5C5F);
  static const PdfColor _midGray = PdfColor.fromInt(0xFF96999D);
  static const PdfColor _lightGray = PdfColors.white;

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => [
        // Dark header
        pw.Container(
          width: double.infinity,
          color: accentColor,
          padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 22),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        resume.personalInfo.fullName.isEmpty
                            ? 'YOUR NAME'
                            : _sanitizePdfText(resume.personalInfo.fullName),
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1.1),
                      ),
                      if (resume.personalInfo.jobTitle?.isNotEmpty ??
                          false) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(_sanitizePdfText(resume.personalInfo.jobTitle!),
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: _lightGray,
                                letterSpacing: 0.5)),
                      ],
                    ]),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (resume.personalInfo.email.isNotEmpty)
                    _acctContact('email', resume.personalInfo.email),
                  if (resume.personalInfo.phone.isNotEmpty)
                    _acctContact('phone', resume.personalInfo.phone),
                  if (resume.personalInfo.address.isNotEmpty)
                    _acctContact('location', resume.personalInfo.address),
                  if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
                    _acctContact('linkedin', resume.personalInfo.linkedIn!),
                  if (resume.personalInfo.website?.isNotEmpty ?? false)
                    _acctContact('website', resume.personalInfo.website!),
                ],
              ),
            ],
          ),
        ),
        // Two-column body matching the template preview
        pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 34),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if ((resume.objective?.isNotEmpty ?? false) ||
                  resume.skills.isNotEmpty) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.objective?.isNotEmpty ?? false) ...[
                            _acctSubSection(
                                'PROFESSIONAL SUMMARY', accentColor),
                            ..._buildSparkSummaryBullets(
                              resume.objective!,
                              accentColor,
                              fontSize: 8.8,
                              lineSpacing: 1.3,
                              bottomPadding: 4,
                              textColor: _darkGray,
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.skills.isNotEmpty) ...[
                            _acctSubSection('SKILLS', accentColor),
                            ...resume.skills.map((s) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 3),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Container(
                                        width: 4,
                                        height: 4,
                                        margin: const pw.EdgeInsets.only(
                                            top: 4, right: 6),
                                        decoration: pw.BoxDecoration(
                                            color: accentColor,
                                            shape: pw.BoxShape.circle),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          _sanitizePdfText(s.name),
                                          style: const pw.TextStyle(
                                              fontSize: 8.8, color: _nearBlack),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            pw.SizedBox(height: 7),
                          ],
                          if (resume.education.isNotEmpty) ...[
                            _acctSubSection('EDUCATION', accentColor),
                            ...resume.education.map((edu) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 7),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        _sanitizePdfText(edu.degree),
                                        style: pw.TextStyle(
                                            fontSize: 9.1,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _nearBlack),
                                      ),
                                      pw.Text(
                                        _sanitizePdfText(edu.institution),
                                        style: const pw.TextStyle(
                                            fontSize: 8.4, color: _darkGray),
                                      ),
                                      pw.Text(
                                        DateFormat('yyyy').format(
                                            edu.endDate ?? edu.startDate),
                                        style: const pw.TextStyle(
                                            fontSize: 8.1, color: _midGray),
                                      ),
                                    ],
                                  ),
                                )),
                            pw.SizedBox(height: 5),
                          ],
                          if (resume.certifications.isNotEmpty) ...[
                            _acctSubSection('CERTIFICATIONS', accentColor),
                            ...resume.certifications.map((cert) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 5),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        _sanitizePdfText(cert.name),
                                        style: pw.TextStyle(
                                            fontSize: 8.8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _nearBlack),
                                      ),
                                      if (cert.issuer.isNotEmpty)
                                        pw.Text(
                                          _sanitizePdfText(cert.issuer),
                                          style: const pw.TextStyle(
                                              fontSize: 8.2, color: _darkGray),
                                        ),
                                    ],
                                  ),
                                )),
                            pw.SizedBox(height: 5),
                          ],
                          if (resume.languages.isNotEmpty) ...[
                            _acctSubSection('LANGUAGES', accentColor),
                            ...resume.languages.map((lang) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 3),
                                  child: pw.Text(
                                    '${_sanitizePdfText(lang.name)}${lang.proficiency.isNotEmpty ? ' | ${_sanitizePdfText(lang.proficiency)}' : ''}',
                                    style: const pw.TextStyle(
                                        fontSize: 8.4, color: _darkGray),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
              ],
              if (resume.experience.isNotEmpty) ...[
                _acctSubSection('EXPERIENCE', accentColor),
                ...resume.experience.map((exp) {
                  final start = DateFormat('MMM yyyy').format(exp.startDate);
                  final end = exp.isCurrentlyWorking
                      ? _present()
                      : DateFormat('MMM yyyy').format(exp.endDate!);
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(_sanitizePdfText(exp.position),
                            style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _nearBlack)),
                        pw.Text(
                          '${_sanitizePdfText(exp.company)} · $start - $end',
                          style: const pw.TextStyle(
                              fontSize: 8.6, color: _midGray),
                        ),
                        if ((exp.location ?? '').isNotEmpty)
                          pw.Text(_sanitizePdfText(exp.location!),
                              style: pw.TextStyle(
                                  fontSize: 8.6,
                                  color: accentColor,
                                  fontWeight: pw.FontWeight.bold)),
                        if (exp.achievements.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          ...exp.achievements.take(3).map((item) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 2),
                                child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      width: 4,
                                      height: 4,
                                      margin: const pw.EdgeInsets.only(
                                          top: 4, right: 6),
                                      decoration: pw.BoxDecoration(
                                          color: accentColor,
                                          shape: pw.BoxShape.circle),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        _sanitizePdfText(item),
                                        style: const pw.TextStyle(
                                            fontSize: 8.7,
                                            color: _nearBlack,
                                            lineSpacing: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ] else if (exp.description.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          ..._buildSummaryBullets(exp.description, accentColor),
                        ],
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 8),
              ],
              if (resume.projects.isNotEmpty) ...[
                _acctSubSection('PROJECTS', accentColor),
                ...resume.projects.map((proj) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_sanitizePdfText(proj.title),
                              style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _nearBlack)),
                          if (proj.description.isNotEmpty)
                            pw.Text(_sanitizePdfText(proj.description),
                                style: const pw.TextStyle(
                                    fontSize: 8.5,
                                    color: _darkGray,
                                    lineSpacing: 1.25)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    ));
    return pdf;
  }

  pw.Widget _acctSubSection(String title, PdfColor accentColor) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: accentColor, width: 1)),
        ),
        child: pw.Text(_h(title),
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _nearBlack,
                letterSpacing: 1)),
      );

  pw.Widget _acctContact(String icon, String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(text,
                style: const pw.TextStyle(fontSize: 8, color: _lightGray),
                maxLines: 1),
            pw.SizedBox(width: 5),
            pw.SizedBox(
              width: 11,
              height: 11,
              child: pw.CustomPaint(
                size: const PdfPoint(11, 11),
                painter: (canvas, size) {
                  final cx = size.x / 2;
                  final cy = size.y / 2;
                  canvas.setFillColor(_darkGray);
                  canvas.drawEllipse(cx, cy, cx, cy);
                  canvas.fillPath();
                  _drawPdfIcon(
                      canvas, icon, cx, cy, cx * 0.52, PdfColors.white);
                },
              ),
            ),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Template: Emerald Executive
// Layout: Emerald-accent executive resume with photo header and clean sections.
// -----------------------------------------------------------------------------
class EmeraldExecutiveTemplate extends PdfTemplate {
  static const PdfColor _green = PdfColor(0.106, 0.396, 0.239);
  static const PdfColor _bodyText = PdfColor(0.12, 0.12, 0.12);
  static const PdfColor _grayText = PdfColor(0.45, 0.45, 0.45);
  static const PdfColor _dividerClr = PdfColor(0.82, 0.82, 0.82);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();

    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildAvatar(resume, photoBytes),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _buildHeaderInfo(resume)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 8, color: _green),
          pw.SizedBox(height: 14),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _sectionHeading('SUMMARY'),
            ..._buildSummaryBullets(
                _sanitizePdfText(resume.objective!), _green),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _sectionHeading('PROFESSIONAL EXPERIENCE'),
            ...resume.experience.map(_buildExperience),
            pw.SizedBox(height: 8),
          ],
          if (resume.education.isNotEmpty) ...[
            _sectionHeading('EDUCATION'),
            ...resume.education.map(_buildEducation),
            pw.SizedBox(height: 8),
          ],
          if (resume.skills.isNotEmpty) ...[
            _sectionHeading('SKILLS'),
            pw.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: resume.skills
                  .map(
                    (skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _dividerClr, width: 0.8),
                        borderRadius: pw.BorderRadius.circular(4),
                        color: const PdfColor(0.96, 0.98, 0.96),
                      ),
                      child: pw.Text(
                        _sanitizePdfText(skill.name),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: _bodyText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 12),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _sectionHeading('CERTIFICATIONS'),
            ...resume.certifications.map(
              (cert) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(
                  '${_sanitizePdfText(cert.name)}${cert.issuer.isNotEmpty ? ' | ${_sanitizePdfText(cert.issuer)}' : ''}',
                  style: const pw.TextStyle(fontSize: 8.5, color: _bodyText),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          if (resume.projects.isNotEmpty) ...[
            _sectionHeading('PROJECTS'),
            ...resume.projects.map(
              (project) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(project.title),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _bodyText,
                      ),
                    ),
                    if (project.description.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _sanitizePdfText(project.description),
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: _grayText,
                            lineSpacing: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          if (resume.languages.isNotEmpty) ...[
            _sectionHeading('LANGUAGES'),
            pw.Wrap(
              spacing: 14,
              runSpacing: 4,
              children: resume.languages
                  .map(
                    (lang) => pw.Text(
                      '${_sanitizePdfText(lang.name)} (${_sanitizePdfText(lang.proficiency)})',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: _bodyText,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildAvatar(ResumeModel resume, Uint8List? photoBytes) {
    final initials = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0])
            .join()
            .toUpperCase()
        : 'YN';

    return pw.Container(
      width: 84,
      height: 84,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _green, width: 2),
        color: _green,
      ),
      child: pw.ClipOval(
        child: photoBytes != null
            ? pw.Image(
                pw.MemoryImage(photoBytes),
                width: 84,
                height: 84,
                fit: pw.BoxFit.cover,
              )
            : pw.Center(
                child: pw.Text(
                  initials,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
      ),
    );
  }

  pw.Widget _buildHeaderInfo(ResumeModel resume) {
    final contacts = <pw.Widget>[];
    if (resume.personalInfo.phone.isNotEmpty) {
      contacts.add(_contactItem('phone', resume.personalInfo.phone));
    }
    if (resume.personalInfo.email.isNotEmpty) {
      if (contacts.isNotEmpty) contacts.add(pw.SizedBox(width: 14));
      contacts.add(_contactItem('email', resume.personalInfo.email));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          (resume.personalInfo.fullName.isEmpty
                  ? 'YOUR NAME'
                  : resume.personalInfo.fullName)
              .toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _green,
            letterSpacing: 1.2,
          ),
        ),
        if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            _sanitizePdfText(resume.personalInfo.jobTitle!),
            style: const pw.TextStyle(
              fontSize: 10,
              color: _grayText,
              letterSpacing: 0.3,
            ),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Container(height: 0.8, color: _dividerClr),
        pw.SizedBox(height: 6),
        if (contacts.isNotEmpty) pw.Row(children: contacts),
        if (resume.personalInfo.address.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          _contactItem('location', resume.personalInfo.address),
        ],
        if (resume.personalInfo.linkedIn?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: 3),
          _contactItem('linkedin', resume.personalInfo.linkedIn!),
        ],
      ],
    );
  }

  pw.Widget _buildExperience(Experience exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(exp.position),
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _bodyText,
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(exp.company),
                  style: const pw.TextStyle(fontSize: 8.5, color: _green),
                ),
              ),
              pw.Text(
                '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                style: const pw.TextStyle(fontSize: 7.5, color: _grayText),
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              _sanitizePdfText(exp.description),
              style: const pw.TextStyle(
                fontSize: 8,
                color: _bodyText,
                lineSpacing: 1.35,
              ),
            ),
          ],
          if (exp.achievements.isNotEmpty)
            ...exp.achievements.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 4,
                      margin: const pw.EdgeInsets.only(top: 3, right: 5),
                      decoration: const pw.BoxDecoration(
                        color: _green,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _sanitizePdfText(item),
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: _bodyText,
                          lineSpacing: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildEducation(Education edu) {
    final end = edu.isCurrentlyStudying
        ? _present()
        : (edu.endDate != null ? DateFormat('yyyy').format(edu.endDate!) : '');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(edu.institution),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _bodyText,
            ),
          ),
          pw.Text(
            _sanitizePdfText(edu.degree),
            style: const pw.TextStyle(fontSize: 8.5, color: _green),
          ),
          if (edu.fieldOfStudy.isNotEmpty)
            pw.Text(
              _sanitizePdfText(edu.fieldOfStudy),
              style: const pw.TextStyle(fontSize: 8, color: _grayText),
            ),
          pw.Text(
            '${DateFormat('yyyy').format(edu.startDate)} - $end',
            style: const pw.TextStyle(fontSize: 7.5, color: _grayText),
          ),
        ],
      ),
    );
  }

  pw.Widget _contactItem(String iconType, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          margin: const pw.EdgeInsets.only(right: 4),
          child: pw.CustomPaint(
            size: const PdfPoint(10, 10),
            painter: (canvas, size) {
              final cx = size.x / 2;
              final cy = size.y / 2;
              canvas.setFillColor(_green);
              canvas.drawEllipse(cx, cy, cx, cy);
              canvas.fillPath();
              _drawPdfIcon(
                  canvas, iconType, cx, cy, cx * 0.52, PdfColors.white);
            },
          ),
        ),
        pw.Text(
          _sanitizePdfText(text),
          style: const pw.TextStyle(fontSize: 8, color: _bodyText),
        ),
      ],
    );
  }

  pw.Widget _sectionHeading(String text) {
    return _buildRightBarSectionHeader(
      text,
      textColor: _green,
      dividerColor: _green,
      fontSize: 10.5,
      letterSpacing: 0.5,
      marginBottom: 8,
      titleBottomSpacing: 2,
      lineThickness: 1.5,
      barHeight: 10,
    );
  }
}

//   - Projects / Experience: "Title | Company" row + date on right + bullets
//   - Education: Degree | Institution + dates + detail bullets
//   - Awards / Certifications: simple bullets
// -----------------------------------------------------------------------------
class EntryLevelTemplate extends PdfTemplate {
  static const PdfColor _darkText = PdfColor.fromInt(0xFF1E1E1E);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF555555);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    const double hPad = 42.0;
    // Use the user-selected accent colour for the header so template-screen and PDF match
    final headerBg = accentColor;

    final contactParts = <String>[
      if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
      if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
      if (resume.personalInfo.address.isNotEmpty) resume.personalInfo.address,
      if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
        resume.personalInfo.linkedIn!,
      if ((resume.personalInfo.github ?? '').isNotEmpty)
        resume.personalInfo.github!,
      if ((resume.personalInfo.website ?? '').isNotEmpty)
        resume.personalInfo.website!,
    ];

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero, // zero margin � header fills full width
      build: (ctx) {
        final body = <pw.Widget>[];

        // -- Full-width header ---------------------------------------------
        body.add(pw.Container(
          width: double.infinity,
          color: headerBg,
          padding: const pw.EdgeInsets.fromLTRB(hPad, 18, hPad, 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Name
              pw.Text(
                _sanitizePdfText(resume.personalInfo.fullName.isEmpty
                    ? 'YOUR NAME'
                    : resume.personalInfo.fullName.toUpperCase()),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                  letterSpacing: 1.0,
                ),
              ),
              // Job title
              if ((resume.personalInfo.jobTitle ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  _sanitizePdfText(resume.personalInfo.jobTitle!),
                  style: pw.TextStyle(fontSize: 11, color: accentColor),
                ),
              ],
              // Contact row � white text, always visible on dark bg
              if (contactParts.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  contactParts.map(_sanitizePdfText).join('   �   '),
                  style: const pw.TextStyle(fontSize: 8, color: _white),
                ),
              ],
            ],
          ),
        ));

        // Spacer at top of body
        body.add(pw.SizedBox(height: 14));

        // -- Helper to wrap each body section with horizontal padding ------
        pw.Widget padded(pw.Widget child) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: hPad),
              child: child,
            );

        // -- Professional Summary ------------------------------------------
        if (resume.objective?.isNotEmpty ?? false) {
          body.add(_elBand(_h('Professional Summary'), accentColor, hPad));
          body.add(padded(pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildSummaryBullets(resume.objective!, accentColor),
            ),
          )));
        }

        // -- Technical Skills ---------------------------------------------
        if (resume.skills.isNotEmpty) {
          body.add(_elBand(_h('Technical Skills'), accentColor, hPad));
          final skills = resume.skills;
          final rows = <pw.Widget>[];
          for (int i = 0; i < skills.length; i += 2) {
            final left = skills[i];
            final right = i + 1 < skills.length ? skills[i + 1] : null;
            rows.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(children: [
                pw.Expanded(child: _elBullet(left.name, accentColor)),
                pw.Expanded(
                    child: right != null
                        ? _elBullet(right.name, accentColor)
                        : pw.SizedBox()),
              ]),
            ));
          }
          body.add(padded(pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: pw.Column(children: rows),
          )));
        }

        // -- Projects -----------------------------------------------------
        if (resume.projects.isNotEmpty) {
          body.add(_elBand(_h('Projects'), accentColor, hPad));
          for (final proj in resume.projects) {
            body.add(padded(pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          _sanitizePdfText(proj.title) +
                              ((proj.url ?? '').isNotEmpty
                                  ? '  |  ${_sanitizePdfText(proj.url!)}'
                                  : ''),
                          style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkText),
                        ),
                      ),
                    ],
                  ),
                  if (proj.technologies.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Technologies: ${proj.technologies.join(', ')}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                  if (proj.description.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    ..._buildSummaryBullets(proj.description, _mutedText),
                  ],
                ],
              ),
            )));
          }
        }

        // -- Education ----------------------------------------------------
        if (resume.education.isNotEmpty) {
          body.add(_elBand(_h('Education'), accentColor, hPad));
          for (final edu in resume.education) {
            final dateStr = '${DateFormat('MMM yyyy').format(edu.startDate)} - '
                '${edu.isCurrentlyStudying ? _present() : (edu.endDate != null ? DateFormat('MMM yyyy').format(edu.endDate!) : '')}';
            body.add(padded(pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${_sanitizePdfText(edu.degree)}${edu.fieldOfStudy.isNotEmpty ? ' AND ${_sanitizePdfText(edu.fieldOfStudy)}' : ''}  |  ${_sanitizePdfText(edu.institution)}${edu.location != null && (edu.location ?? '').isNotEmpty ? ' (${_sanitizePdfText(edu.location!)})' : ''}',
                          style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkText),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(dateStr,
                          style: const pw.TextStyle(
                              fontSize: 9, color: _mutedText)),
                    ],
                  ),
                  if (edu.grade != null && (edu.grade ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    _elBullet('GPA: ${edu.grade!}', _mutedText),
                  ],
                ],
              ),
            )));
          }
          body.add(pw.SizedBox(height: 4));
        }

        // -- Work Experience ----------------------------------------------
        if (resume.experience.isNotEmpty) {
          body.add(_elBand(_h('Work Experience'), accentColor, hPad));
          for (final exp in resume.experience) {
            final dateStr = '${DateFormat('MMM yyyy').format(exp.startDate)} - '
                '${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}';
            body.add(padded(pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${_sanitizePdfText(exp.position)}  |  '
                          '${_sanitizePdfText(exp.company)}'
                          '${(exp.location ?? '').isNotEmpty ? '  |  ${_sanitizePdfText(exp.location!)}' : ''}',
                          style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkText),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(dateStr,
                          style: const pw.TextStyle(
                              fontSize: 9, color: _mutedText)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  if (exp.achievements.isNotEmpty)
                    ..._buildSummaryBullets(
                        exp.achievements.join('\n'), _mutedText)
                  else if (exp.description.isNotEmpty)
                    ..._buildSummaryBullets(exp.description, _mutedText),
                ],
              ),
            )));
          }
        }

        // -- Awards & Achievements ----------------------------------------
        if (resume.certifications.isNotEmpty) {
          body.add(_elBand(_h('Awards & Achievements'), accentColor, hPad));
          body.add(padded(pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.certifications
                  .map((cert) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: _elBullet(
                          '${_sanitizePdfText(cert.name)}, '
                          '${_sanitizePdfText(cert.issuer)}'
                          '${cert.credentialId != null && cert.credentialId!.isNotEmpty ? ' (${cert.credentialId})' : ''}',
                          _mutedText,
                        ),
                      ))
                  .toList(),
            ),
          )));
        }

        // -- Languages ----------------------------------------------------
        if (resume.languages.isNotEmpty) {
          body.add(_elBand(_h('Languages'), accentColor, hPad));
          body.add(padded(pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: pw.Wrap(
              spacing: 16,
              runSpacing: 5,
              children: resume.languages
                  .map((l) => _elBullet(
                      '${_sanitizePdfText(l.name)} (${l.proficiency})',
                      _mutedText))
                  .toList(),
            ),
          )));
        }

        body.add(pw.SizedBox(height: 36)); // bottom padding
        return body;
      },
    ));

    return doc;
  }

  // -- Full-width coloured band section header -----------------------------
  pw.Widget _elBand(String title, PdfColor accentColor, double hPad) =>
      pw.Container(
        width: double.infinity,
        color: accentColor,
        padding: pw.EdgeInsets.symmetric(horizontal: hPad, vertical: 5),
        margin: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: _white,
            letterSpacing: 1.0,
          ),
        ),
      );

  // -- Bullet line: drawn circle dot + text --------------------------------
  pw.Widget _elBullet(String text, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 12,
              child: pw.CustomPaint(
                size: const PdfPoint(12, 12),
                painter: (canvas, size) {
                  canvas.setFillColor(color);
                  canvas.drawEllipse(6, 6, 2.2, 2.2);
                  canvas.fillPath();
                },
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(text),
                style:
                    pw.TextStyle(fontSize: 9.5, color: color, lineSpacing: 1.3),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Executive Classic Template
// Two-tone header, left-bar section dividers — sophisticated senior style.
// ════════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════════
// Executive Classic Template
// Full-width colored header (name · title · contact row), then white body
// with left-accent-bar section headers and horizontal dividers — faithful to
// the Harper Russo Canva reference design.
// ════════════════════════════════════════════════════════════════════════════
class ExecutiveClassicTemplate extends PdfTemplate {
  static const _bodyText = PdfColor.fromInt(0xFF1A2535);
  static const _mutedText = PdfColor.fromInt(0xFF6B7280);
  static const _lightGray = PdfColor.fromInt(0xFFF9FAFB);
  static const _lineGray = PdfColor.fromInt(0xFFE5E7EB);
  static const _headerBg = PdfColor.fromInt(0xFF1B3A5C);
  static const _headerStripe = PdfColor.fromInt(0xFF162D46);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [
        // ── Full-width colour header ─────────────────────────────────────
        pw.Container(
          color: _headerBg,
          padding: const pw.EdgeInsets.fromLTRB(44, 32, 44, 26),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (resume.personalInfo.fullName.isEmpty
                          ? 'YOUR NAME'
                          : _sanitizePdfText(resume.personalInfo.fullName))
                      .toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 2.0),
                ),
                if ((resume.personalInfo.jobTitle ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    _sanitizePdfText(resume.personalInfo.jobTitle!)
                        .toUpperCase(),
                    style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor(1, 1, 1, 0.72),
                        letterSpacing: 2.5),
                  ),
                ],
                pw.SizedBox(height: 14),
                // Contact row — phone · email · location
                pw.Row(children: [
                  if (resume.personalInfo.phone.isNotEmpty) ...[
                    pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.white)),
                    _ecDot(),
                  ],
                  if (resume.personalInfo.email.isNotEmpty) ...[
                    pw.Text(_sanitizePdfText(resume.personalInfo.email),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.white)),
                    _ecDot(),
                  ],
                  if (resume.personalInfo.address.isNotEmpty)
                    pw.Text(_sanitizePdfText(resume.personalInfo.address),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.white)),
                ]),
              ]),
        ),
        // Thin accent stripe below header
        pw.Container(height: 4, color: _headerStripe),

        // ── SUMMARY ─────────────────────────────────────────────────────
        if (resume.objective?.isNotEmpty ?? false) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 22, 44, 6),
            child: _ecSectionHeader('SUMMARY', accentColor),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 0, 44, 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildSummaryBullets(
                  _sanitizePdfText(resume.objective!), accentColor),
            ),
          ),
        ],

        // ── WORK EXPERIENCE ─────────────────────────────────────────────
        if (resume.experience.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 6, 44, 6),
            child: _ecSectionHeader('WORK EXPERIENCE', accentColor),
          ),
          ...resume.experience.map((exp) {
            final start = DateFormat('MMM yyyy').format(exp.startDate);
            final end = exp.isCurrentlyWorking
                ? _present()
                : DateFormat('MMM yyyy').format(exp.endDate!);
            return pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 2, 44, 14),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Expanded(
                          child: pw.Text(_sanitizePdfText(exp.position),
                              style: pw.TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _bodyText))),
                      pw.Text('$start – $end',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _mutedText)),
                    ]),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      [
                        _sanitizePdfText(exp.company),
                        if ((exp.location ?? '').isNotEmpty)
                          _sanitizePdfText(exp.location!),
                      ].join('  ·  '),
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    if (exp.achievements.isNotEmpty)
                      ..._buildSummaryBullets(
                          exp.achievements.join('\n'), accentColor)
                    else if (exp.description.isNotEmpty)
                      ..._buildSummaryBullets(exp.description, accentColor),
                  ]),
            );
          }),
        ],

        // ── EDUCATION ───────────────────────────────────────────────────
        if (resume.education.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 6, 44, 6),
            child: _ecSectionHeader('EDUCATION', accentColor),
          ),
          ...resume.education.map((edu) {
            final start = DateFormat('yyyy').format(edu.startDate);
            final end = edu.isCurrentlyStudying
                ? _present()
                : DateFormat('yyyy').format(edu.endDate!);
            return pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 2, 44, 10),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Expanded(
                          child: pw.Text(_sanitizePdfText(edu.degree),
                              style: pw.TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _bodyText))),
                      pw.Text('$start – $end',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _mutedText)),
                    ]),
                    pw.Text(_sanitizePdfText(edu.institution),
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: pw.FontWeight.bold)),
                    if (edu.fieldOfStudy.isNotEmpty)
                      pw.Text(_sanitizePdfText(edu.fieldOfStudy),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _mutedText)),
                    if ((edu.description ?? '').isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(_sanitizePdfText(edu.description!),
                            style: const pw.TextStyle(
                                fontSize: 9,
                                color: _mutedText,
                                lineSpacing: 1.5)),
                      ),
                  ]),
            );
          }),
        ],

        // ── CORE COMPETENCIES (Skills) ───────────────────────────────────
        if (resume.skills.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 6, 44, 6),
            child: _ecSectionHeader('CORE COMPETENCIES', accentColor),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 2, 44, 16),
            child: pw.Wrap(
              spacing: 6,
              runSpacing: 5,
              children: resume.skills
                  .map((s) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: _lightGray,
                          border: pw.Border.all(color: _lineGray, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(_sanitizePdfText(s.name),
                            style: const pw.TextStyle(
                                fontSize: 9, color: _bodyText)),
                      ))
                  .toList(),
            ),
          ),
        ],

        // ── CERTIFICATIONS ───────────────────────────────────────────────
        if (resume.certifications.isNotEmpty) ...[
          pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 6, 44, 6),
              child: _ecSectionHeader('CERTIFICATIONS', accentColor)),
          ...resume.certifications.map((c) => pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(44, 2, 44, 6),
                child: pw.Row(children: [
                  pw.Container(
                      width: 5,
                      height: 5,
                      margin: const pw.EdgeInsets.only(top: 1, right: 8),
                      decoration: pw.BoxDecoration(
                          color: accentColor, shape: pw.BoxShape.circle)),
                  pw.Expanded(
                      child: pw.Text(_sanitizePdfText(c.name),
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _bodyText))),
                  pw.Text(_sanitizePdfText(c.issuer),
                      style:
                          const pw.TextStyle(fontSize: 9, color: _mutedText)),
                ]),
              )),
        ],

        // ── LANGUAGES ───────────────────────────────────────────────────
        if (resume.languages.isNotEmpty) ...[
          pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 6, 44, 6),
              child: _ecSectionHeader('LANGUAGES', accentColor)),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 2, 44, 18),
            child: pw.Wrap(
              spacing: 24,
              runSpacing: 5,
              children: resume.languages
                  .map((l) => pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                              text: _sanitizePdfText(l.name),
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _bodyText)),
                          pw.TextSpan(
                              text: '  ${_sanitizePdfText(l.proficiency)}',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _mutedText)),
                        ]),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    ));
    return doc;
  }

  /// Small dot separator used in the contact row.
  pw.Widget _ecDot() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
        child: pw.Container(
            width: 4,
            height: 4,
            decoration: const pw.BoxDecoration(
                color: PdfColor(1, 1, 1, 0.5), shape: pw.BoxShape.circle)),
      );

  /// Section heading: left coloured accent bar + bold label + horizontal rule.
  pw.Widget _ecSectionHeader(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(
              width: 4,
              height: 18,
              color: accentColor,
              margin: const pw.EdgeInsets.only(right: 10)),
          pw.Text(_h(title),
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1.2)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(height: 0.8, color: _lineGray)),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Corporate Template
// Two-column layout from the top — no header bar.
// LEFT dark navy panel (~38%): circular photo, contacts, education, skills
//   with accent checkmarks.
// RIGHT white body (~62%): name + ALL-CAPS title, thin accent line, then
//   Profile paragraph and Work Experience entries with date-range indents.
// Faithful to the Avery Davis Canva reference design.
// ════════════════════════════════════════════════════════════════════════════
class CorporateTemplate extends PdfTemplate {
  static const _sidebarBg = PdfColor.fromInt(0xFF1B2A3B);
  static const _sidebarFg = PdfColors.white;
  static const _sidebarMuted = PdfColor.fromInt(0xFFB0BEC5);
  static const _bodyText = PdfColor.fromInt(0xFF1E293B);
  static const _mutedText = PdfColor.fromInt(0xFF64748B);
  static const _lineGray = PdfColor.fromInt(0xFFE2E8F0);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    // Decode profile photo if one was provided
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Dark left sidebar ──────────────────────────────────────────
          pw.Container(
            width: 146,
            color: _sidebarBg,
            padding: const pw.EdgeInsets.fromLTRB(16, 30, 12, 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Circular profile photo / initials avatar
                pw.Center(
                    child: pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: photoBytes != null
                        ? null
                        : PdfColor(accentColor.red, accentColor.green,
                            accentColor.blue, 0.35),
                    border: pw.Border.all(color: accentColor, width: 2.5),
                    image: photoBytes != null
                        ? pw.DecorationImage(
                            image: pw.MemoryImage(photoBytes),
                            fit: pw.BoxFit.cover)
                        : null,
                  ),
                  child: photoBytes == null
                      ? pw.Center(
                          child: pw.Text(
                              resume.personalInfo.fullName.isNotEmpty
                                  ? resume.personalInfo.fullName
                                      .split(' ')
                                      .take(2)
                                      .map((n) => n[0])
                                      .join()
                                      .toUpperCase()
                                  : 'YN',
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _sidebarFg)))
                      : null,
                )),
                pw.SizedBox(height: 24),

                // Contacts
                _corpSideSection('CONTACTS', accentColor),
                if (resume.personalInfo.email.isNotEmpty)
                  _sideItem(resume.personalInfo.email),
                if (resume.personalInfo.phone.isNotEmpty)
                  _sideItem(resume.personalInfo.phone),
                if (resume.personalInfo.address.isNotEmpty)
                  _sideItem(resume.personalInfo.address),
                if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                  _sideItem(resume.personalInfo.linkedIn!),
                pw.SizedBox(height: 16),

                // Education
                if (resume.education.isNotEmpty) ...[
                  _corpSideSection('EDUCATION', accentColor),
                  ...resume.education.take(2).map((edu) {
                    final yr = edu.endDate?.year ?? edu.startDate.year;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 9),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(_sanitizePdfText(edu.degree),
                                style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _sidebarFg)),
                            pw.Text(_sanitizePdfText(edu.institution),
                                style: pw.TextStyle(
                                    fontSize: 8.5, color: accentColor)),
                            pw.Text('$yr',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _sidebarMuted)),
                          ]),
                    );
                  }),
                  pw.SizedBox(height: 16),
                ],

                // Skills — accent checkmarks
                if (resume.skills.isNotEmpty) ...[
                  _corpSideSection('SKILLS', accentColor),
                  ...resume.skills.map((s) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Checkmark circle
                              pw.Container(
                                width: 12,
                                height: 12,
                                margin: const pw.EdgeInsets.only(
                                    top: 0.5, right: 8),
                                decoration: pw.BoxDecoration(
                                    color: accentColor,
                                    shape: pw.BoxShape.circle),
                                child: pw.Center(
                                    child: pw.Text('✓',
                                        style: const pw.TextStyle(
                                            fontSize: 7.5,
                                            color: PdfColors.white))),
                              ),
                              pw.Expanded(
                                  child: pw.Text(_sanitizePdfText(s.name),
                                      style: const pw.TextStyle(
                                          fontSize: 9, color: _sidebarMuted))),
                            ]),
                      )),
                ],

                // Languages
                if (resume.languages.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  _corpSideSection('LANGUAGES', accentColor),
                  ...resume.languages.map((l) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                            '${_sanitizePdfText(l.name)}  |  ${_sanitizePdfText(l.proficiency)}',
                            style: const pw.TextStyle(
                                fontSize: 9, color: _sidebarMuted)),
                      )),
                ],
              ],
            ),
          ),

          // ── White right body ───────────────────────────────────────────
          pw.Expanded(
              child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 30, 18, 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name
                pw.Text(
                  (resume.personalInfo.fullName.isEmpty
                          ? 'YOUR NAME'
                          : _sanitizePdfText(resume.personalInfo.fullName))
                      .toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _bodyText,
                      letterSpacing: 1.2),
                ),
                if ((resume.personalInfo.jobTitle ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(resume.personalInfo.jobTitle!)
                        .toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2.0),
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Container(height: 2.5, color: accentColor),
                pw.SizedBox(height: 18),

                // Profile / Objective
                if (resume.objective?.isNotEmpty ?? false) ...[
                  _corpBodySection('PROFILE', accentColor),
                  ..._buildSummaryBullets(
                      _sanitizePdfText(resume.objective!), accentColor),
                  pw.SizedBox(height: 16),
                ],

                // Projects
                if (resume.projects.isNotEmpty) ...[
                  _corpBodySection('PROJECTS', accentColor),
                  ...resume.projects.map((p) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(_sanitizePdfText(p.title),
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _bodyText)),
                              if (p.description.isNotEmpty)
                                ..._buildSummaryBullets(
                                    p.description, accentColor),
                            ]),
                      )),
                  pw.SizedBox(height: 10),
                ],

                // Work Experience
                if (resume.experience.isNotEmpty) ...[
                  _corpBodySection('WORK EXPERIENCE', accentColor),
                  ...resume.experience.map((exp) {
                    final start = DateFormat('MMM yyyy').format(exp.startDate);
                    final end = exp.isCurrentlyWorking
                        ? _present()
                        : DateFormat('MMM yyyy').format(exp.endDate!);
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 14),
                      child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Date column
                            pw.SizedBox(
                              width: 40,
                              child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(start,
                                        style: const pw.TextStyle(
                                            fontSize: 8.5, color: _mutedText)),
                                    pw.Text('–',
                                        style: const pw.TextStyle(
                                            fontSize: 8.5, color: _mutedText)),
                                    pw.Text(end,
                                        style: const pw.TextStyle(
                                            fontSize: 8.5, color: _mutedText)),
                                  ]),
                            ),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 1.2,
                                height: 56,
                                color: PdfColor(accentColor.red,
                                    accentColor.green, accentColor.blue, 0.3)),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                                child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(_sanitizePdfText(exp.position),
                                    style: pw.TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _bodyText)),
                                pw.Text(
                                  '${_sanitizePdfText(exp.company)}${(exp.location ?? '').isNotEmpty ? '  ·  ${_sanitizePdfText(exp.location!)}' : ''}',
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      color: accentColor,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 4),
                                if (exp.achievements.isNotEmpty)
                                  ..._buildSummaryBullets(
                                      exp.achievements.join('\n'), accentColor)
                                else if (exp.description.isNotEmpty)
                                  ..._buildSummaryBullets(
                                      exp.description, accentColor),
                              ],
                            )),
                          ]),
                    );
                  }),
                ],

                // Certifications
                if (resume.certifications.isNotEmpty) ...[
                  _corpBodySection('CERTIFICATIONS', accentColor),
                  ...resume.certifications.map((c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Row(children: [
                          pw.Expanded(
                              child: pw.Text(_sanitizePdfText(c.name),
                                  style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _bodyText))),
                          pw.Text(_sanitizePdfText(c.issuer),
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _mutedText)),
                        ]),
                      )),
                ],
              ],
            ),
          )),
        ],
      ),
    ));
    return doc;
  }

  pw.Widget _corpSideSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.2)),
              pw.Container(
                  height: 1,
                  color: PdfColor(accentColor.red, accentColor.green,
                      accentColor.blue, 0.5),
                  margin: const pw.EdgeInsets.only(top: 4, bottom: 6)),
            ]),
      );

  pw.Widget _sideItem(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(_sanitizePdfText(text),
            style: const pw.TextStyle(
                fontSize: 8.5, color: _sidebarMuted, lineSpacing: 1.4)),
      );

  pw.Widget _corpBodySection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _bodyText,
                      letterSpacing: 0.8)),
              pw.Container(
                  height: 1,
                  color: _lineGray,
                  margin: const pw.EdgeInsets.only(top: 4)),
            ]),
      );
}

class MonoNovaTemplate extends PdfTemplate {
  static const _text = PdfColor.fromInt(0xFF2F2C29);
  static const _muted = PdfColor.fromInt(0xFF6B6763);
  static const _rule = PdfColor.fromInt(0xFFC7C2BC);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      resume.personalInfo.fullName.isEmpty
                          ? 'YOUR NAME'
                          : _sanitizePdfText(resume.personalInfo.fullName),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                      pw.Text(
                        _sanitizePdfText(resume.personalInfo.jobTitle!),
                        style: const pw.TextStyle(fontSize: 13, color: _muted),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (resume.personalInfo.address.isNotEmpty)
                    pw.Text(_sanitizePdfText(resume.personalInfo.address),
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                  if (resume.personalInfo.email.isNotEmpty)
                    pw.Text(_sanitizePdfText(resume.personalInfo.email),
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                  if (resume.personalInfo.phone.isNotEmpty)
                    pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1.2, color: _rule),
          pw.SizedBox(height: 12),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _monoSection('PROFESSIONAL SUMMARY'),
            pw.Text(_sanitizePdfText(resume.objective!),
                style: const pw.TextStyle(
                    fontSize: 10, color: _muted, lineSpacing: 1.55),
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 12),
          ],
          if (resume.experience.isNotEmpty) ...[
            _monoSection('EXPERIENCE'),
            ...resume.experience.map((exp) {
              final end = exp.isCurrentlyWorking
                  ? _present()
                  : DateFormat('MMM yyyy').format(exp.endDate!);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(_sanitizePdfText(exp.position),
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _text)),
                        ),
                        pw.Text(
                          '${DateFormat('MMM yyyy').format(exp.startDate)} - $end',
                          style:
                              const pw.TextStyle(fontSize: 8.8, color: _muted),
                        ),
                      ],
                    ),
                    pw.Text(
                      '${_sanitizePdfText(exp.company)}${(exp.location ?? '').isNotEmpty ? ' | ${_sanitizePdfText(exp.location!)}' : ''}',
                      style: pw.TextStyle(
                          fontSize: 9.2,
                          color: _muted,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    if (exp.achievements.isNotEmpty)
                      ..._buildSummaryBullets(
                          exp.achievements.take(4).join('\n'), _text)
                    else if (exp.description.isNotEmpty)
                      ..._buildSummaryBullets(exp.description, _text),
                  ],
                ),
              );
            }),
          ],
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (resume.education.isNotEmpty)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _monoSection('EDUCATION'),
                      ...resume.education.take(3).map((edu) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(_sanitizePdfText(edu.degree),
                                    style: pw.TextStyle(
                                        fontSize: 9.6,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _text)),
                                pw.Text(_sanitizePdfText(edu.institution),
                                    style: const pw.TextStyle(
                                        fontSize: 8.8, color: _muted)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              if (resume.education.isNotEmpty && resume.skills.isNotEmpty)
                pw.SizedBox(width: 16),
              if (resume.skills.isNotEmpty)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _monoSection('SKILLS'),
                      ...resume.skills.map((skill) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Text('• ${_sanitizePdfText(skill.name)}',
                                style: const pw.TextStyle(
                                    fontSize: 8.8, color: _muted)),
                          )),
                    ],
                  ),
                ),
            ],
          ),
          if (resume.languages.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _monoSection('LANGUAGES'),
            pw.Wrap(
              spacing: 18,
              runSpacing: 4,
              children: resume.languages
                  .map((l) => pw.Text(
                      '${_sanitizePdfText(l.name)} ${_sanitizePdfText(l.proficiency)}',
                      style: const pw.TextStyle(fontSize: 8.8, color: _muted)))
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _monoSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_h(title),
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _text)),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: _rule),
          ],
        ),
      );
}

class SlateArcTemplate extends PdfTemplate {
  static const _ink = PdfColor.fromInt(0xFF3B434B);
  static const _muted = PdfColor.fromInt(0xFF707780);
  static const _soft = PdfColor.fromInt(0xFFE1E3E6);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 26, 34, 26),
        build: (context) => [
          pw.Stack(
            children: [
              pw.Container(
                height: 96,
                width: double.infinity,
                decoration: const pw.BoxDecoration(color: _soft),
              ),
              pw.Positioned(
                left: 0,
                right: 110,
                top: 0,
                bottom: 0,
                child: pw.Container(color: PdfColors.white),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            (resume.personalInfo.fullName.isEmpty
                                    ? 'YOUR NAME'
                                    : _sanitizePdfText(
                                        resume.personalInfo.fullName))
                                .toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Text(
                              _sanitizePdfText(resume.personalInfo.jobTitle!),
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  color: accentColor,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 72,
                      height: 72,
                      decoration: photoBytes == null
                          ? pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: _ink,
                              border: pw.Border.all(
                                  color: PdfColors.white, width: 3),
                            )
                          : pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(
                                  color: PdfColors.white, width: 3),
                              image: pw.DecorationImage(
                                image: pw.MemoryImage(photoBytes),
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                      child: photoBytes == null
                          ? pw.Center(
                              child: pw.Text(
                                  resume.personalInfo.fullName.isNotEmpty
                                      ? resume.personalInfo.fullName
                                          .split(' ')
                                          .take(2)
                                          .map((n) => n[0])
                                          .join()
                                          .toUpperCase()
                                      : 'YN',
                                  style: pw.TextStyle(
                                      fontSize: 18,
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold)),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          if (resume.personalInfo.phone.isNotEmpty ||
              resume.personalInfo.email.isNotEmpty ||
              (resume.personalInfo.linkedIn ?? '').isNotEmpty ||
              (resume.personalInfo.website ?? '').isNotEmpty) ...[
            _slateSection('CONTACT', accentColor),
            pw.Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (resume.personalInfo.phone.isNotEmpty)
                  pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                      style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
                if (resume.personalInfo.email.isNotEmpty)
                  pw.Text(_sanitizePdfText(resume.personalInfo.email),
                      style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
                if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                  pw.Text(_sanitizePdfText(resume.personalInfo.linkedIn!),
                      style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
                if ((resume.personalInfo.website ?? '').isNotEmpty)
                  pw.Text(_sanitizePdfText(resume.personalInfo.website!),
                      style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          if (resume.objective?.isNotEmpty ?? false) ...[
            _slateSection('PROFILE', accentColor),
            ..._buildArrowPointerBullets(
              resume.objective!,
              accentColor,
              fontSize: 8.9,
              lineSpacing: 1.38,
              bottomPadding: 4,
              textColor: _muted,
            ),
            pw.SizedBox(height: 12),
          ],
          if (resume.experience.isNotEmpty) ...[
            _slateSection('EXPERIENCE', accentColor),
            ...resume.experience.map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(children: [
                        pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                                color: accentColor, shape: pw.BoxShape.circle)),
                        pw.Container(
                            width: 1,
                            height: 32,
                            color: PdfColor(accentColor.red, accentColor.green,
                                accentColor.blue, 0.3)),
                      ]),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(_sanitizePdfText(exp.position),
                                      style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                          color: _ink)),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                                  textAlign: pw.TextAlign.right,
                                  style: const pw.TextStyle(
                                      fontSize: 8.1, color: _muted),
                                ),
                              ],
                            ),
                            pw.Text(_sanitizePdfText(exp.company),
                                style: pw.TextStyle(
                                    fontSize: 8.8,
                                    color: accentColor,
                                    fontWeight: pw.FontWeight.bold)),
                            if (exp.description.isNotEmpty)
                              ..._buildSummaryBullets(
                                  exp.description, accentColor),
                            if (exp.achievements.isNotEmpty)
                              ..._buildSummaryBullets(
                                  exp.achievements.join('\n'), accentColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (resume.projects.isNotEmpty) ...[
            _slateSection('PROJECTS', accentColor),
            ...resume.projects.map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.3, color: _muted, lineSpacing: 1.3),
                            textAlign: pw.TextAlign.justify),
                    ],
                  ),
                )),
          ],
          if (resume.education.isNotEmpty) ...[
            _slateSection('EDUCATION', accentColor),
            ...resume.education.take(3).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(edu.institution),
                          style:
                              const pw.TextStyle(fontSize: 8.2, color: _muted)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
          ],
          if (resume.skills.isNotEmpty) ...[
            _slateSection('SKILLS', accentColor),
            pw.Wrap(
              spacing: 10,
              runSpacing: 4,
              children: resume.skills.take(8).map((skill) {
                return pw.Text('• ${_sanitizePdfText(skill.name)}',
                    style: const pw.TextStyle(fontSize: 8.2, color: _muted));
              }).toList(),
            ),
            pw.SizedBox(height: 8),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _slateSection('CERTIFICATIONS', accentColor),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(cert.name),
                          style: pw.TextStyle(
                              fontSize: 8.3,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      if (cert.issuer.isNotEmpty)
                        pw.Text(_sanitizePdfText(cert.issuer),
                            style: const pw.TextStyle(
                                fontSize: 7.8, color: _muted)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
          ],
          if (resume.languages.isNotEmpty) ...[
            _slateSection('LANGUAGES', accentColor),
            ...resume.languages.map((lang) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    '${_sanitizePdfText(lang.name)} | ${_sanitizePdfText(lang.proficiency)}',
                    style: const pw.TextStyle(fontSize: 8.1, color: _muted),
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _slateSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                      letterSpacing: 1.2)),
              pw.Container(
                  height: 1,
                  color: accentColor,
                  margin: const pw.EdgeInsets.only(top: 3)),
            ]),
      );
}

class EditorialFrameTemplate extends PdfTemplate {
  static const _ink = PdfColor.fromInt(0xFF2C2A28);
  static const _muted = PdfColor.fromInt(0xFF6E675F);
  static const _line = PdfColor.fromInt(0xFFD8CEC4);
  static const _editorialAccent = PdfColor.fromInt(0xFFB08863);
  static const _paper = PdfColor.fromInt(0xFFF8F5F1);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 30),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _paper),
          ),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 82,
                height: 104,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _line, width: 1),
                ),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: photoBytes == null
                        ? const PdfColor(0.95, 0.93, 0.90)
                        : null,
                    image: photoBytes != null
                        ? pw.DecorationImage(
                            image: pw.MemoryImage(photoBytes),
                            fit: pw.BoxFit.cover)
                        : null,
                  ),
                  child: photoBytes == null
                      ? pw.Center(
                          child: pw.Text('PHOTO',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _editorialAccent)),
                        )
                      : null,
                ),
              ),
              pw.SizedBox(width: 22),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (resume.personalInfo.fullName.isEmpty
                              ? 'YOUR NAME'
                              : _sanitizePdfText(resume.personalInfo.fullName))
                          .toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: _editorialAccent,
                          letterSpacing: 1.2),
                    ),
                    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.jobTitle!),
                          style:
                              const pw.TextStyle(fontSize: 12, color: _muted)),
                    pw.Container(
                        height: 1,
                        color: _line,
                        margin: const pw.EdgeInsets.symmetric(vertical: 10)),
                    pw.Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        if (resume.personalInfo.phone.isNotEmpty)
                          pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                              style: const pw.TextStyle(
                                  fontSize: 8.4, color: _muted)),
                        if (resume.personalInfo.email.isNotEmpty)
                          pw.Text(_sanitizePdfText(resume.personalInfo.email),
                              style: const pw.TextStyle(
                                  fontSize: 8.4, color: _muted)),
                        if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                          pw.Text(
                              _sanitizePdfText(resume.personalInfo.linkedIn!),
                              style: const pw.TextStyle(
                                  fontSize: 8.4, color: _muted)),
                        if ((resume.personalInfo.website ?? '').isNotEmpty)
                          pw.Text(
                              _sanitizePdfText(resume.personalInfo.website!),
                              style: const pw.TextStyle(
                                  fontSize: 8.4, color: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _editSection('PERSONAL PROFILE'),
            ..._buildArrowPointerBullets(
              resume.objective!,
              _editorialAccent,
              fontSize: 9.1,
              lineSpacing: 1.42,
              bottomPadding: 4,
              textColor: _muted,
            ),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _editSection('WORK EXPERIENCE'),
            ...resume.experience.map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(_sanitizePdfText(exp.position),
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _ink)),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(
                                fontSize: 8.1, color: _muted),
                          ),
                        ],
                      ),
                      pw.Text(_sanitizePdfText(exp.company),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              color: _editorialAccent,
                              fontWeight: pw.FontWeight.bold)),
                      if (exp.description.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.description,
                          _editorialAccent,
                          fontSize: 8.8,
                          lineSpacing: 1.35,
                          bottomPadding: 4,
                          textColor: _muted,
                        ),
                      if (exp.achievements.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.achievements.join('\n'),
                          _editorialAccent,
                          fontSize: 8.8,
                          lineSpacing: 1.35,
                          bottomPadding: 4,
                          textColor: _muted,
                        ),
                    ],
                  ),
                )),
          ],
          if (resume.education.isNotEmpty) ...[
            _editSection('EDUCATION'),
            ...resume.education.take(3).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(edu.institution),
                          style:
                              const pw.TextStyle(fontSize: 8.1, color: _muted)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 10),
          ],
          if (resume.skills.isNotEmpty) ...[
            _editSection('EXPERTISE'),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: resume.skills.take(8).map((skill) {
                return pw.Text(_sanitizePdfText(skill.name),
                    style: const pw.TextStyle(fontSize: 8.4, color: _muted));
              }).toList(),
            ),
            pw.SizedBox(height: 10),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _editSection('CERTIFICATIONS'),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(cert.name),
                          style: pw.TextStyle(
                              fontSize: 8.3,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      if (cert.issuer.isNotEmpty)
                        pw.Text(_sanitizePdfText(cert.issuer),
                            style: const pw.TextStyle(
                                fontSize: 7.8, color: _muted)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 10),
          ],
          if (resume.languages.isNotEmpty) ...[
            _editSection('LANGUAGES'),
            ...resume.languages.map((lang) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    '${_sanitizePdfText(lang.name)} | ${_sanitizePdfText(lang.proficiency)}',
                    style: const pw.TextStyle(fontSize: 8.1, color: _muted),
                  ),
                )),
          ],
          if (resume.projects.isNotEmpty) ...[
            _editSection('PROJECTS'),
            ...resume.projects.map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 9.2,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: _muted,
                                lineSpacing: 1.32),
                            textAlign: pw.TextAlign.justify),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _editSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _editorialAccent,
                      letterSpacing: 1.1)),
              pw.Container(
                  height: 1,
                  color: _line,
                  margin: const pw.EdgeInsets.only(top: 3)),
            ]),
      );
}

class GraphiteColumnTemplate extends PdfTemplate {
  static const _panel = PdfColor.fromInt(0xFF5B5D62);
  static const _ink = PdfColor.fromInt(0xFF2C2E32);
  static const _muted = PdfColor.fromInt(0xFF6E7176);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    const sideW = 150.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(sideW + 24, 28, 28, 24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  width: sideW,
                  color: _panel,
                  padding: const pw.EdgeInsets.fromLTRB(18, 24, 14, 24),
                  child: context.pageNumber == 1
                      ? _graphiteSidebar(resume, accentColor, photoBytes)
                      : pw.SizedBox(),
                ),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            (resume.personalInfo.fullName.isEmpty
                    ? 'YOUR NAME'
                    : _sanitizePdfText(resume.personalInfo.fullName))
                .toUpperCase(),
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
            pw.Text(_sanitizePdfText(resume.personalInfo.jobTitle!),
                style: const pw.TextStyle(fontSize: 12, color: _muted)),
          pw.Container(
              height: 1,
              color: PdfColor(
                  accentColor.red, accentColor.green, accentColor.blue, 0.45),
              margin: const pw.EdgeInsets.symmetric(vertical: 10)),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _graphiteMainSection('PROFILE', accentColor),
            ..._buildSummaryBullets(resume.objective!, accentColor),
            pw.SizedBox(height: 10),
          ],
          if (resume.experience.isNotEmpty) ...[
            _graphiteMainSection('WORK EXPERIENCE', accentColor),
            ...resume.experience.take(3).map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(exp.position),
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(exp.company),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold)),
                      if (exp.description.isNotEmpty)
                        ..._buildSummaryBullets(
                          exp.description,
                          accentColor,
                        ),
                    ],
                  ),
                )),
          ],
          if (resume.education.isNotEmpty) ...[
            _graphiteMainSection('EDUCATION', accentColor),
            ...resume.education.take(3).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                              fontSize: 9.6,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(edu.institution),
                          style:
                              const pw.TextStyle(fontSize: 8.6, color: _muted)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _graphiteSidebar(
    ResumeModel resume,
    PdfColor accentColor,
    Uint8List? photoBytes,
  ) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Container(
              width: 78,
              height: 96,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.white, width: 1.5),
                color:
                    photoBytes == null ? const PdfColor(1, 1, 1, 0.12) : null,
                image: photoBytes != null
                    ? pw.DecorationImage(
                        image: pw.MemoryImage(photoBytes),
                        fit: pw.BoxFit.cover,
                      )
                    : null,
              ),
              child: photoBytes == null
                  ? pw.Center(
                      child: pw.Text('PHOTO',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold)),
                    )
                  : null,
            ),
          ),
          pw.SizedBox(height: 18),
          _graphiteSection('CONTACT', accentColor),
          if (resume.personalInfo.phone.isNotEmpty)
            _graphiteLine(resume.personalInfo.phone),
          if (resume.personalInfo.email.isNotEmpty)
            _graphiteLine(resume.personalInfo.email),
          if (resume.personalInfo.address.isNotEmpty)
            _graphiteLine(resume.personalInfo.address),
          pw.SizedBox(height: 14),
          if (resume.skills.isNotEmpty) ...[
            _graphiteSection('SKILLS', accentColor),
            ...resume.skills.take(6).map((skill) => _graphiteLine(skill.name)),
          ],
        ],
      );

  pw.Widget _graphiteSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1.1)),
              pw.Container(
                  height: 1,
                  color: accentColor,
                  margin: const pw.EdgeInsets.only(top: 3)),
            ]),
      );

  pw.Widget _graphiteLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(_sanitizePdfText(text),
            style: const pw.TextStyle(
                fontSize: 8.2, color: PdfColor(1, 1, 1, 0.7))),
      );

  pw.Widget _graphiteMainSection(String title, PdfColor accentColor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.1)),
              pw.Container(
                  height: 1,
                  color: PdfColor(accentColor.red, accentColor.green,
                      accentColor.blue, 0.45),
                  margin: const pw.EdgeInsets.only(top: 3)),
            ]),
      );
}

class RosewoodPanelTemplate extends PdfTemplate {
  static const _ink = PdfColor.fromInt(0xFF403A38);
  static const _muted = PdfColor.fromInt(0xFF7C7571);
  static const _soft = PdfColor.fromInt(0xFFF1E7E4);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    const sideW = 160.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(sideW + 22, 24, 24, 24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  width: sideW,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _soft,
                    border: pw.Border(
                      right: pw.BorderSide(
                        color: PdfColor(accentColor.red, accentColor.green,
                            accentColor.blue, 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: context.pageNumber == 1
                      ? _roseSidebar(resume, accentColor, photoBytes)
                      : pw.SizedBox(),
                ),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            (resume.personalInfo.fullName.isEmpty
                    ? 'YOUR NAME'
                    : _sanitizePdfText(resume.personalInfo.fullName))
                .toUpperCase(),
            style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: accentColor),
          ),
          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
            pw.Text(_sanitizePdfText(resume.personalInfo.jobTitle!),
                style: const pw.TextStyle(fontSize: 12, color: _ink)),
          pw.SizedBox(height: 12),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _roseMainSection('ABOUT ME', accentColor),
            ..._buildArrowPointerBullets(
              resume.objective!,
              accentColor,
              fontSize: 9,
              lineSpacing: 1.4,
              bottomPadding: 4,
              textColor: _ink,
            ),
            pw.SizedBox(height: 10),
          ],
          if (resume.experience.isNotEmpty) ...[
            _roseMainSection('WORK EXPERIENCE', accentColor),
            ...resume.experience.take(3).map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(exp.position),
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(exp.company),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold)),
                      if (exp.description.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.description,
                          accentColor,
                          fontSize: 8.5,
                          lineSpacing: 1.32,
                          bottomPadding: 4,
                          textColor: _ink,
                        ),
                    ],
                  ),
                )),
          ],
          if (resume.projects.isNotEmpty) ...[
            _roseMainSection('PROJECTS', accentColor),
            ...resume.projects.map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.2,
                                color: _muted,
                                lineSpacing: 1.25),
                            textAlign: pw.TextAlign.justify),
                    ],
                  ),
                )),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _roseMainSection('CERTIFICATIONS', accentColor),
            ...resume.certifications.take(3).map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(_sanitizePdfText(cert.name),
                      style: const pw.TextStyle(fontSize: 8.4, color: _ink)),
                )),
          ],
          if (resume.skills.isNotEmpty) ...[
            _roseMainSection('SKILLS', accentColor),
            ...resume.skills.take(4).map((skill) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(skill.name),
                          style:
                              const pw.TextStyle(fontSize: 8.3, color: _muted)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        height: 5,
                        width: 90,
                        color: PdfColor(accentColor.red, accentColor.green,
                            accentColor.blue, 0.22),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _roseSidebar(
    ResumeModel resume,
    PdfColor accentColor,
    Uint8List? photoBytes,
  ) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Container(
              width: 82,
              height: 82,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: photoBytes == null
                    ? PdfColor(accentColor.red, accentColor.green,
                        accentColor.blue, 0.14)
                    : null,
                image: photoBytes != null
                    ? pw.DecorationImage(
                        image: pw.MemoryImage(photoBytes),
                        fit: pw.BoxFit.cover,
                      )
                    : null,
              ),
              child: photoBytes == null
                  ? pw.Center(
                      child: pw.Text('PHOTO',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor)),
                    )
                  : null,
            ),
          ),
          pw.SizedBox(height: 14),
          _roseSection('CONTACT', accentColor),
          if (resume.personalInfo.phone.isNotEmpty)
            _roseLine(resume.personalInfo.phone),
          if (resume.personalInfo.address.isNotEmpty)
            _roseLine(resume.personalInfo.address),
          if (resume.personalInfo.email.isNotEmpty)
            _roseLine(resume.personalInfo.email),
          pw.SizedBox(height: 14),
          if (resume.education.isNotEmpty) ...[
            _roseSection('EDUCATION', accentColor),
            ...resume.education.take(2).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.Text(_sanitizePdfText(edu.institution),
                          style:
                              const pw.TextStyle(fontSize: 8.1, color: _muted)),
                    ],
                  ),
                )),
          ],
        ],
      );

  pw.Widget _roseSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(title,
            style: pw.TextStyle(
                fontSize: 9.4,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
                letterSpacing: 1)),
      );

  pw.Widget _roseMainSection(String title, PdfColor accentColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(_h(title),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor)),
              pw.Container(
                  height: 1,
                  width: 110,
                  color: PdfColor(accentColor.red, accentColor.green,
                      accentColor.blue, 0.6),
                  margin: const pw.EdgeInsets.only(top: 3)),
            ]),
      );

  pw.Widget _roseLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(_sanitizePdfText(text),
            style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
      );
}

class DesignerProfileTemplate extends PdfTemplate {
  static const _navy = PdfColor.fromInt(0xFF2F467B);
  static const _navyDeep = PdfColor.fromInt(0xFF22345E);
  static const _ink = PdfColor.fromInt(0xFF24304A);
  static const _muted = PdfColor.fromInt(0xFF677181);
  static const _soft = PdfColor.fromInt(0xFFE5EAF5);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    // Add professional role sections if this is a role-specific template
    final normalizedResume = resume.templateId == 'designer_profile'
        ? resume.copyWith(
            customSections: ensureProfessionalRoleSections(resume))
        : resume;
    final photoBytes =
        (normalizedResume.personalInfo.profileImage?.isNotEmpty ?? false)
            ? base64Decode(normalizedResume.personalInfo.profileImage!)
            : null;
    const sideW = 150.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(sideW + 24, 24, 24, 24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  width: sideW,
                  color: _navy,
                  padding: const pw.EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: context.pageNumber == 1
                      ? _designerSidebar(resume, photoBytes)
                      : pw.SizedBox(),
                ),
                pw.Expanded(
                    child:
                        pw.Container(color: const PdfColor(0.97, 0.98, 0.99))),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (resume.personalInfo.fullName.isEmpty
                              ? 'YOUR NAME'
                              : _sanitizePdfText(resume.personalInfo.fullName))
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                      pw.Text(
                        _sanitizePdfText(resume.personalInfo.jobTitle!),
                        style: const pw.TextStyle(
                            fontSize: 12, color: _muted, lineSpacing: 1.2),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: _soft,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(
                  _sanitizePdfText(resume.personalInfo.address.isEmpty
                      ? 'Creative Resume'
                      : resume.personalInfo.address),
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    color: _navyDeep,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.Container(
              height: 1,
              color: _soft,
              margin: const pw.EdgeInsets.symmetric(vertical: 12)),
          if (resume.objective?.isNotEmpty ?? false) ...[
            _designerMainSection('ABOUT ME'),
            ..._buildArrowPointerBullets(
              resume.objective!,
              _navy,
              fontSize: 9,
              lineSpacing: 1.42,
              bottomPadding: 4,
              textColor: _muted,
            ),
            pw.SizedBox(height: 10),
          ],
          if (resume.experience.isNotEmpty) ...[
            _designerMainSection('EXPERIENCE'),
            ...resume.experience.take(3).map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(_sanitizePdfText(exp.position),
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _ink)),
                          ),
                          pw.Text(
                            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                            style: const pw.TextStyle(
                                fontSize: 8.2, color: _muted),
                          ),
                        ],
                      ),
                      pw.Text(_sanitizePdfText(exp.company),
                          style: pw.TextStyle(
                              fontSize: 8.7,
                              color: _navy,
                              fontWeight: pw.FontWeight.bold)),
                      if (exp.description.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.description,
                          _navy,
                          fontSize: 8.5,
                          lineSpacing: 1.34,
                          bottomPadding: 4,
                          textColor: _muted,
                        ),
                      if (exp.achievements.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.achievements.take(3).join('\n'),
                          _navy,
                          fontSize: 8.5,
                          lineSpacing: 1.34,
                          bottomPadding: 4,
                          textColor: _muted,
                        ),
                    ],
                  ),
                )),
          ],
          if (resume.projects.isNotEmpty) ...[
            _designerMainSection('PROJECTS'),
            ...resume.projects.map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.2,
                                color: _muted,
                                lineSpacing: 1.25),
                            textAlign: pw.TextAlign.justify),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _designerSidebar(ResumeModel resume, Uint8List? photoBytes) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Container(
              width: 84,
              height: 84,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color:
                    photoBytes == null ? const PdfColor(1, 1, 1, 0.18) : null,
                border: pw.Border.all(
                    color: const PdfColor(1, 1, 1, 0.7), width: 2),
                image: photoBytes != null
                    ? pw.DecorationImage(
                        image: pw.MemoryImage(photoBytes),
                        fit: pw.BoxFit.cover,
                      )
                    : null,
              ),
              child: photoBytes == null
                  ? pw.Center(
                      child: pw.Text(
                        resume.personalInfo.fullName.isNotEmpty
                            ? resume.personalInfo.fullName
                                .split(' ')
                                .take(2)
                                .map((n) => n[0])
                                .join()
                                .toUpperCase()
                            : 'DP',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          pw.SizedBox(height: 20),
          _designerSideSection('CONTACT'),
          if (resume.personalInfo.phone.isNotEmpty)
            _designerSideLine(resume.personalInfo.phone),
          if (resume.personalInfo.email.isNotEmpty)
            _designerSideLine(resume.personalInfo.email),
          if (resume.personalInfo.address.isNotEmpty)
            _designerSideLine(resume.personalInfo.address),
          if ((resume.personalInfo.website ?? '').isNotEmpty)
            _designerSideLine(resume.personalInfo.website!),
          pw.SizedBox(height: 14),
          if (resume.education.isNotEmpty) ...[
            _designerSideSection('EDUCATION'),
            ...resume.education.take(2).map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(edu.degree),
                          style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.Text(_sanitizePdfText(edu.institution),
                          style: const pw.TextStyle(
                              fontSize: 7.8, color: PdfColor(1, 1, 1, 0.72))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 10),
          ],
          if (resume.skills.isNotEmpty) ...[
            _designerSideSection('SKILLS'),
            ...resume.skills.take(6).map((skill) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(skill.name),
                          style: const pw.TextStyle(
                              fontSize: 8.2, color: PdfColors.white)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                          height: 4,
                          width: 88,
                          decoration: const pw.BoxDecoration(
                              color: PdfColor(1, 1, 1, 0.18),
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(10)))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 10),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _designerSideSection('CERTIFICATIONS'),
            ...resume.certifications.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(cert.name),
                          style: pw.TextStyle(
                              fontSize: 8.2,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      if (cert.issuer.isNotEmpty)
                        pw.Text(_sanitizePdfText(cert.issuer),
                            style: const pw.TextStyle(
                                fontSize: 7.7, color: PdfColor(1, 1, 1, 0.72))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 10),
          ],
          if (resume.languages.isNotEmpty) ...[
            _designerSideSection('LANGUAGES'),
            ...resume.languages.map((lang) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${_sanitizePdfText(lang.name)}  |  ${_sanitizePdfText(lang.proficiency)}',
                    style: const pw.TextStyle(
                        fontSize: 7.8, color: PdfColor(1, 1, 1, 0.78)),
                  ),
                )),
          ],
        ],
      );

  pw.Widget _designerSideSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 9.6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1.1)),
            pw.Container(
                height: 1,
                color: const PdfColor(1, 1, 1, 0.32),
                margin: const pw.EdgeInsets.only(top: 3)),
          ],
        ),
      );

  pw.Widget _designerSideLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(_sanitizePdfText(text),
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColor(1, 1, 1, 0.78))),
      );

  pw.Widget _designerMainSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_h(title),
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyDeep,
                    letterSpacing: 1.05)),
            pw.Container(
                height: 1,
                width: 120,
                color: _soft,
                margin: const pw.EdgeInsets.only(top: 3)),
          ],
        ),
      );
}

class ModernEdgeTemplate extends PdfTemplate {
  static const _green = PdfColor.fromInt(0xFF6CB38E);
  static const _greenDark = PdfColor.fromInt(0xFF4D7F66);
  static const _greenSoft = PdfColor.fromInt(0xFFEAF4ED);
  static const _ink = PdfColor.fromInt(0xFF31444C);
  static const _muted = PdfColor.fromInt(0xFF67756C);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;
    const sideW = 154.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(sideW + 22, 26, 24, 24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  width: sideW,
                  color: _green,
                  padding: const pw.EdgeInsets.fromLTRB(16, 22, 16, 20),
                  child: context.pageNumber == 1
                      ? _modernEdgeSidebar(resume, photoBytes)
                      : pw.SizedBox(),
                ),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            _sanitizePdfText(
              resume.personalInfo.fullName.isEmpty
                  ? 'YOUR NAME'
                  : resume.personalInfo.fullName,
            ),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
            pw.Text(
              _sanitizePdfText(resume.personalInfo.jobTitle!),
              style: pw.TextStyle(
                fontSize: 11,
                color: _muted,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (resume.personalInfo.phone.isNotEmpty)
                _modernEdgeChip(resume.personalInfo.phone),
              if (resume.personalInfo.email.isNotEmpty)
                _modernEdgeChip(resume.personalInfo.email),
              if (resume.personalInfo.address.isNotEmpty)
                _modernEdgeChip(resume.personalInfo.address),
            ],
          ),
          pw.Container(
              height: 1,
              color: _greenSoft,
              margin: const pw.EdgeInsets.symmetric(vertical: 12)),
          if (resume.experience.isNotEmpty) ...[
            _modernEdgeSection('EXPERIENCE'),
            ...resume.experience.take(3).map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(_sanitizePdfText(exp.position),
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    color: _ink,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Text(
                            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                            style: const pw.TextStyle(
                                fontSize: 7.8, color: _muted),
                          ),
                        ],
                      ),
                      pw.Text(_sanitizePdfText(exp.company),
                          style: pw.TextStyle(
                              fontSize: 8.4,
                              color: _greenDark,
                              fontWeight: pw.FontWeight.bold)),
                      if (exp.description.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.description,
                          _greenDark,
                          fontSize: 8.3,
                          lineSpacing: 1.3,
                          bottomPadding: 3,
                          textColor: _muted,
                        ),
                      if (exp.achievements.isNotEmpty)
                        ..._buildArrowPointerBullets(
                          exp.achievements.take(3).join('\n'),
                          _greenDark,
                          fontSize: 8.3,
                          lineSpacing: 1.3,
                          bottomPadding: 3,
                          textColor: _muted,
                        ),
                    ],
                  ),
                )),
          ],
          if (resume.projects.isNotEmpty) ...[
            _modernEdgeSection('PROJECTS'),
            ...resume.projects.map((project) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_sanitizePdfText(project.title),
                          style: pw.TextStyle(
                              fontSize: 8.8,
                              color: _ink,
                              fontWeight: pw.FontWeight.bold)),
                      if (project.description.isNotEmpty)
                        pw.Text(_sanitizePdfText(project.description),
                            style: const pw.TextStyle(
                                fontSize: 8.1,
                                color: _muted,
                                lineSpacing: 1.25)),
                    ],
                  ),
                )),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _modernEdgeSection('CERTIFICATIONS'),
            ...resume.certifications.take(3).map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(_sanitizePdfText(cert.name),
                      style: const pw.TextStyle(fontSize: 8.2, color: _muted)),
                )),
          ],
        ],
      ),
    );

    return doc;
  }

  pw.Widget _modernEdgeSidebar(ResumeModel resume, Uint8List? photoBytes) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Container(
              width: 72,
              height: 72,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: photoBytes == null ? PdfColors.white : null,
                border: pw.Border.all(color: PdfColors.white, width: 2),
                image: photoBytes != null
                    ? pw.DecorationImage(
                        image: pw.MemoryImage(photoBytes),
                        fit: pw.BoxFit.cover,
                      )
                    : null,
              ),
              child: photoBytes == null
                  ? pw.Center(
                      child: pw.Text(
                        resume.personalInfo.fullName.isNotEmpty
                            ? resume.personalInfo.fullName
                                .split(' ')
                                .take(2)
                                .map((n) => n[0])
                                .join()
                                .toUpperCase()
                            : 'ME',
                        style: pw.TextStyle(
                          fontSize: 22,
                          color: _green,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          pw.SizedBox(height: 16),
          _modernEdgeSideSection('SUMMARY'),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColor(1, 1, 1, 0.16),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              _modernEdgeSummary(resume.objective),
              style: const pw.TextStyle(
                  fontSize: 8.1, color: PdfColors.white, lineSpacing: 1.3),
            ),
          ),
          pw.SizedBox(height: 12),
          if (resume.skills.isNotEmpty) ...[
            _modernEdgeSideSection('SKILLS'),
            ...resume.skills.take(5).map((skill) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('• ${_sanitizePdfText(skill.name)}',
                      style: const pw.TextStyle(
                          fontSize: 8.1, color: PdfColors.white)),
                )),
            pw.SizedBox(height: 10),
          ],
        ],
      );

  String _modernEdgeSummary(String? text) {
    final sanitized = _sanitizePdfText(text);
    if (sanitized.length <= 220) {
      return sanitized;
    }
    return '${sanitized.substring(0, 220).trim()}...';
  }

  pw.Widget _modernEdgeSideSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_h(title),
                style: pw.TextStyle(
                    fontSize: 9.2,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1)),
            pw.Container(
                height: 1,
                color: const PdfColor(1, 1, 1, 0.35),
                margin: const pw.EdgeInsets.only(top: 3)),
          ],
        ),
      );

  pw.Widget _modernEdgeSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_h(title),
                style: pw.TextStyle(
                    fontSize: 10.4,
                    color: _greenDark,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.05)),
            pw.Container(
                height: 1,
                color: _greenSoft,
                margin: const pw.EdgeInsets.only(top: 3)),
          ],
        ),
      );

  pw.Widget _modernEdgeChip(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const pw.BoxDecoration(
          color: _greenSoft,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
        ),
        child: pw.Text(_sanitizePdfText(text),
            style: const pw.TextStyle(fontSize: 7.8, color: _greenDark)),
      );
}

class MinimalCleanTemplate extends PdfTemplate {
  static const _bg = PdfColor.fromInt(0xFFE7E7EB);
  static const _card = PdfColor.fromInt(0xFFF9FAFC);
  static const _blue = PdfColor.fromInt(0xFF8FB0D6);
  static const _blueDark = PdfColor.fromInt(0xFF5B7597);
  static const _ink = PdfColor.fromInt(0xFF2F374A);
  static const _muted = PdfColor.fromInt(0xFF6E7380);
  static const _sand = PdfColor.fromInt(0xFFE9DDD5);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = (resume.personalInfo.profileImage?.isNotEmpty ?? false)
        ? base64Decode(resume.personalInfo.profileImage!)
        : null;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(34, 26, 34, 26),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _bg),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: _card,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 64,
                      height: 64,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: photoBytes == null ? _sand : null,
                        border: pw.Border.all(color: PdfColors.white, width: 2),
                        image: photoBytes != null
                            ? pw.DecorationImage(
                                image: pw.MemoryImage(photoBytes),
                                fit: pw.BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoBytes == null
                          ? pw.Center(
                              child: pw.Text('MC',
                                  style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _blueDark)),
                            )
                          : null,
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            (resume.personalInfo.fullName.isEmpty
                                    ? 'YOUR NAME'
                                    : _sanitizePdfText(
                                        resume.personalInfo.fullName))
                                .toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!),
                                style: const pw.TextStyle(
                                    fontSize: 9.5, color: _muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: const pw.BoxDecoration(
                    color: _blue,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          child: pw.Text(
                              _sanitizePdfText(resume.personalInfo.phone),
                              style: const pw.TextStyle(
                                  fontSize: 7.8, color: PdfColors.white))),
                      pw.Expanded(
                          child: pw.Text(
                              _sanitizePdfText(resume.personalInfo.email),
                              style: const pw.TextStyle(
                                  fontSize: 7.8, color: PdfColors.white))),
                      pw.Expanded(
                          child: pw.Text(
                              _sanitizePdfText(resume.personalInfo.address),
                              style: const pw.TextStyle(
                                  fontSize: 7.8, color: PdfColors.white))),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 120,
                      padding: const pw.EdgeInsets.only(right: 12),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            right: pw.BorderSide(color: _bg, width: 1)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.education.isNotEmpty) ...[
                            _minimalCleanSection('EDUCATION'),
                            ...resume.education.take(2).map((edu) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 7),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(_sanitizePdfText(edu.degree),
                                          style: pw.TextStyle(
                                              fontSize: 8.2,
                                              color: _ink,
                                              fontWeight: pw.FontWeight.bold)),
                                      pw.Text(_sanitizePdfText(edu.institution),
                                          style: const pw.TextStyle(
                                              fontSize: 7.8, color: _muted)),
                                    ],
                                  ),
                                )),
                          ],
                          if (resume.certifications.isNotEmpty) ...[
                            _minimalCleanSection('CERTIFICATIONS'),
                            ...resume.certifications
                                .take(3)
                                .map((cert) => pw.Padding(
                                      padding:
                                          const pw.EdgeInsets.only(bottom: 4),
                                      child: pw.Text(
                                          _sanitizePdfText(cert.name),
                                          style: const pw.TextStyle(
                                              fontSize: 7.8, color: _muted)),
                                    )),
                          ],
                          if (resume.skills.isNotEmpty) ...[
                            _minimalCleanSection('SKILLS'),
                            ...resume.skills.take(5).map((skill) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  child: pw.Text(
                                      '• ${_sanitizePdfText(skill.name)}',
                                      style: const pw.TextStyle(
                                          fontSize: 7.8, color: _muted)),
                                )),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.objective?.isNotEmpty ?? false) ...[
                            _minimalCleanSection('ABOUT ME'),
                            pw.Text(_sanitizePdfText(resume.objective!),
                                style: const pw.TextStyle(
                                    fontSize: 8.1,
                                    color: _muted,
                                    lineSpacing: 1.3),
                                textAlign: pw.TextAlign.justify),
                            pw.SizedBox(height: 10),
                          ],
                          if (resume.experience.isNotEmpty) ...[
                            _minimalCleanSection('EXPERIENCE'),
                            ...resume.experience.take(3).map((exp) =>
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 10),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Expanded(
                                            child: pw.Text(
                                                _sanitizePdfText(exp.position),
                                                style: pw.TextStyle(
                                                    fontSize: 9,
                                                    color: _ink,
                                                    fontWeight:
                                                        pw.FontWeight.bold)),
                                          ),
                                          pw.Text(
                                            '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                                            style: const pw.TextStyle(
                                                fontSize: 7.5, color: _muted),
                                          ),
                                        ],
                                      ),
                                      pw.Text(_sanitizePdfText(exp.company),
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              color: _blueDark,
                                              fontWeight: pw.FontWeight.bold)),
                                      if (exp.description.isNotEmpty)
                                        pw.Text(
                                            _sanitizePdfText(exp.description),
                                            style: const pw.TextStyle(
                                                fontSize: 7.8,
                                                color: _muted,
                                                lineSpacing: 1.25)),
                                    ],
                                  ),
                                )),
                          ],
                          if (resume.projects.isNotEmpty) ...[
                            _minimalCleanSection('PROJECTS'),
                            ...resume.projects.map((project) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 6),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(_sanitizePdfText(project.title),
                                          style: pw.TextStyle(
                                              fontSize: 8.2,
                                              color: _ink,
                                              fontWeight: pw.FontWeight.bold)),
                                      if (project.description.isNotEmpty)
                                        pw.Text(
                                            _sanitizePdfText(
                                                project.description),
                                            style: const pw.TextStyle(
                                                fontSize: 7.8,
                                                color: _muted,
                                                lineSpacing: 1.2)),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _minimalCleanSection(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_h(title),
                style: pw.TextStyle(
                    fontSize: 9.2,
                    color: _blueDark,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.9)),
            pw.Container(
                height: 1,
                color: _bg,
                margin: const pw.EdgeInsets.only(top: 3)),
          ],
        ),
      );
}

Uint8List? _decodeProfilePhoto(ResumeModel resume) {
  final encoded = resume.personalInfo.profileImage;
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

String _resumeInitials(ResumeModel resume, [String fallback = 'CV']) {
  final fullName = resume.personalInfo.fullName.trim();
  if (fullName.isEmpty) return fallback;
  final parts = fullName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return fallback;
  return parts.map((part) => part[0]).join().toUpperCase();
}

String _formatPhotoTemplateExperienceRange(Experience exp) {
  final start = DateFormat('yyyy').format(exp.startDate);
  final end = exp.isCurrentlyWorking
      ? _present().toUpperCase()
      : (exp.endDate != null ? DateFormat('yyyy').format(exp.endDate!) : '');
  return end.isEmpty ? start : '$start - $end';
}

String _formatPhotoTemplateEducationRange(Education edu) {
  final start = DateFormat('yyyy').format(edu.startDate);
  final end = edu.isCurrentlyStudying
      ? _present().toUpperCase()
      : (edu.endDate != null ? DateFormat('yyyy').format(edu.endDate!) : '');
  return end.isEmpty ? start : '$start - $end';
}

String _formatPhotoTemplateProjectRange(Project project) {
  final start = project.startDate != null
      ? DateFormat('yyyy').format(project.startDate!)
      : '';
  final end = project.endDate != null
      ? DateFormat('yyyy').format(project.endDate!)
      : '';
  if (start.isEmpty && end.isEmpty) return '';
  if (start.isEmpty) return end;
  if (end.isEmpty) return start;
  return '$start - $end';
}

String _formatPhotoTemplateCertificationDate(Certification cert) {
  if (cert.issueDate != null) {
    return DateFormat('yyyy').format(cert.issueDate!);
  }
  if (cert.expiryDate != null) {
    return DateFormat('yyyy').format(cert.expiryDate!);
  }
  return '';
}

List<String> _splitPhotoTemplateText(String text, {int? maxItems}) {
  final normalized = _sanitizePdfText(text)
      .split(RegExp(r'\n+|(?<=[.!?])\s+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .map((item) => item.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .toList();
  if (maxItems != null && normalized.length > maxItems) {
    return normalized.take(maxItems).toList();
  }
  return normalized;
}

pw.Widget _photoTemplatePrefixedLines(
  List<String> lines, {
  required String prefix,
  required PdfColor textColor,
  PdfColor? prefixColor,
  double fontSize = 8,
  double spacing = 3,
}) {
  final barColor = prefixColor ?? textColor;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: lines
        .map((line) => pw.Padding(
              padding: pw.EdgeInsets.only(bottom: spacing),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 2.5,
                    height: fontSize * 1.55,
                    margin: const pw.EdgeInsets.only(right: 5, top: 1),
                    color: barColor,
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _sanitizePdfText(line),
                      style: pw.TextStyle(
                        fontSize: fontSize,
                        color: textColor,
                        lineSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList(),
  );
}

pw.Widget _photoTemplateAvatar({
  required Uint8List? photoBytes,
  required String initials,
  required double size,
  required PdfColor borderColor,
  required PdfColor fillColor,
  required PdfColor textColor,
}) {
  return pw.Container(
    width: size,
    height: size,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      color: photoBytes == null ? fillColor : null,
      border: pw.Border.all(color: borderColor, width: 2),
      image: photoBytes != null
          ? pw.DecorationImage(
              image: pw.MemoryImage(photoBytes),
              fit: pw.BoxFit.cover,
            )
          : null,
    ),
    child: photoBytes == null
        ? pw.Center(
            child: pw.Text(
              initials,
              style: pw.TextStyle(
                fontSize: size * 0.26,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          )
        : null,
  );
}

pw.Widget _photoTemplateSectionTitle(
  String title,
  PdfColor color, {
  PdfColor? dividerColor,
  double fontSize = 10,
}) {
  return _buildRightBarSectionHeader(
    title,
    textColor: color,
    dividerColor: dividerColor ?? color,
    fontSize: fontSize,
    letterSpacing: 0.7,
    marginBottom: 6,
    titleBottomSpacing: 3,
    barHeight: 12,
  );
}

pw.Widget _photoTemplateProjectItem(
  Project project, {
  required PdfColor titleColor,
  required PdfColor bodyColor,
  PdfColor? metaColor,
}) {
  final range = _formatPhotoTemplateProjectRange(project);
  final fallbackBody = project.technologies.isNotEmpty
      ? project.technologies.take(4).join(' • ')
      : '';

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(
                    project.title.isEmpty ? 'Project' : project.title),
                style: pw.TextStyle(
                  fontSize: 9.2,
                  color: titleColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (range.isNotEmpty)
              pw.Text(
                range,
                style: pw.TextStyle(
                  fontSize: 7.6,
                  color: metaColor ?? bodyColor,
                ),
              ),
          ],
        ),
        if (project.description.isNotEmpty || fallbackBody.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _sanitizePdfText(project.description.isNotEmpty
                  ? project.description
                  : fallbackBody),
              style: pw.TextStyle(
                fontSize: 8,
                color: bodyColor,
                lineSpacing: 1.25,
              ),
            ),
          ),
      ],
    ),
  );
}

pw.Widget _photoTemplateCertificationItem(
  Certification cert, {
  required PdfColor titleColor,
  required PdfColor bodyColor,
  PdfColor? metaColor,
}) {
  final date = _formatPhotoTemplateCertificationDate(cert);
  final issuer = cert.issuer.trim();

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitizePdfText(cert.name.isEmpty ? 'Certification' : cert.name),
          style: pw.TextStyle(
            fontSize: 8.2,
            color: titleColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (issuer.isNotEmpty || date.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              _sanitizePdfText(issuer.isEmpty
                  ? date
                  : '$issuer${date.isNotEmpty ? ' · $date' : ''}'),
              style: pw.TextStyle(
                fontSize: 7.6,
                color: metaColor ?? bodyColor,
              ),
            ),
          ),
      ],
    ),
  );
}

// ── Minimal Clean ATS Template ─────────────────────────────────────────────────
class MinimalCleanAtsTemplate extends PdfTemplate {
  static const _wine = PdfColor.fromInt(0xFF7D2E2C);
  static const _wineDark = PdfColor.fromInt(0xFF5D211F);
  static const _sand = PdfColor.fromInt(0xFFF3ECE7);
  static const _paper = PdfColor.fromInt(0xFFFFFBF8);
  static const _line = PdfColor.fromInt(0xFFE0D1C8);
  static const _ink = PdfColor.fromInt(0xFF332724);
  static const _muted = PdfColor.fromInt(0xFF76665E);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'MC');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 145,
                padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: const pw.BoxDecoration(color: _sand),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: _photoTemplateAvatar(
                        photoBytes: photoBytes,
                        initials: initials,
                        size: 72,
                        borderColor: _wine,
                        fillColor: const PdfColor.fromInt(0xFFE8D8CF),
                        textColor: _wine,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _photoTemplateSectionTitle('CONTACT', _wine,
                        dividerColor: _line, fontSize: 9),
                    if (resume.personalInfo.phone.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                          style:
                              const pw.TextStyle(fontSize: 8, color: _muted)),
                    if (resume.personalInfo.email.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.email),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    if (resume.personalInfo.address.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.address),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    pw.SizedBox(height: 14),
                    _photoTemplateSectionTitle('SKILLS', _wine,
                        dividerColor: _line, fontSize: 9),
                    ...resume.skills.take(6).map(
                          (skill) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text('• ${_sanitizePdfText(skill.name)}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted)),
                          ),
                        ),
                    if (resume.languages.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      _photoTemplateSectionTitle('LANGUAGES', _wine,
                          dividerColor: _line, fontSize: 9),
                      ...resume.languages.take(2).map(
                            (language) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '${_sanitizePdfText(language.name)} ${_sanitizePdfText(language.proficiency)}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: const pw.BoxDecoration(color: _wine),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(
                                    resume.personalInfo.fullName.isEmpty
                                        ? 'YOUR NAME'
                                        : resume.personalInfo.fullName)
                                .toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 24,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!),
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    if (resume.objective?.isNotEmpty ?? false) ...[
                      _photoTemplateSectionTitle('ABOUT ME', _wine,
                          dividerColor: _line),
                      pw.Text(
                        _sanitizePdfText(resume.objective!),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _muted,
                          lineSpacing: 1.35,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    if (resume.experience.isNotEmpty) ...[
                      _photoTemplateSectionTitle('EXPERIENCE', _wine,
                          dividerColor: _line),
                      ...resume.experience.take(3).map(
                            (exp) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          _sanitizePdfText(exp.position),
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      pw.Text(
                                        _formatPhotoTemplateExperienceRange(
                                            exp),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                      _sanitizePdfText(exp.company),
                                      style: const pw.TextStyle(
                                        fontSize: 8.5,
                                        color: _wineDark,
                                      ),
                                    ),
                                  ),
                                  if (exp.description.isNotEmpty)
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(top: 3),
                                      child: pw.Text(
                                        _sanitizePdfText(exp.description),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _muted,
                                          lineSpacing: 1.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.education.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _photoTemplateSectionTitle('EDUCATION', _wine,
                          dividerColor: _line),
                      ...resume.education.take(2).map(
                            (edu) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          _sanitizePdfText(edu.degree.isEmpty
                                              ? edu.fieldOfStudy
                                              : edu.degree),
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding:
                                              const pw.EdgeInsets.only(top: 2),
                                          child: pw.Text(
                                            _sanitizePdfText(edu.institution),
                                            style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.Text(
                                    _formatPhotoTemplateEducationRange(edu),
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.references.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _photoTemplateSectionTitle('REFERENCES', _wine,
                          dividerColor: _line),
                      pw.Row(
                        children: resume.references.take(2).map((ref) {
                          return pw.Expanded(
                            child: pw.Container(
                              margin: pw.EdgeInsets.only(
                                  right: ref == resume.references.first ? 6 : 0,
                                  left: ref == resume.references.first ? 0 : 6),
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(color: _sand),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    _sanitizePdfText(ref.name),
                                    style: pw.TextStyle(
                                      fontSize: 8.8,
                                      color: _ink,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 2),
                                    child: pw.Text(
                                      _sanitizePdfText(
                                          '${ref.position}${ref.company.isNotEmpty ? ' · ${ref.company}' : ''}'),
                                      style: const pw.TextStyle(
                                        fontSize: 7.4,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc;
  }
}

class ProfessionalToneTemplate extends PdfTemplate {
  static const _navy = PdfColor.fromInt(0xFF4C647F);
  static const _navyDark = PdfColor.fromInt(0xFF33475F);
  static const _sidebar = PdfColor.fromInt(0xFFE5ECF3);
  static const _paper = PdfColor.fromInt(0xFFF8F8F8);
  static const _line = PdfColor.fromInt(0xFFD8E0E8);
  static const _ink = PdfColor.fromInt(0xFF243242);
  static const _muted = PdfColor.fromInt(0xFF6C7784);
  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    // Add professional role sections if this is a role-specific template
    final normalizedResume = resume.templateId == 'professional_tone'
        ? resume.copyWith(
            customSections: ensureProfessionalRoleSections(resume))
        : resume;
    final photoBytes = _decodeProfilePhoto(normalizedResume);
    final initials = _resumeInitials(normalizedResume, 'PT');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 142,
                padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: const pw.BoxDecoration(color: _sidebar),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: _photoTemplateAvatar(
                        photoBytes: photoBytes,
                        initials: initials,
                        size: 70,
                        borderColor: _navy,
                        fillColor: const PdfColor.fromInt(0xFFD7DFE8),
                        textColor: _navy,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _photoTemplateSectionTitle('CONTACT', _navy,
                        dividerColor: _line, fontSize: 9),
                    if (resume.personalInfo.phone.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                          style:
                              const pw.TextStyle(fontSize: 8, color: _muted)),
                    if (resume.personalInfo.email.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.email),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    if (resume.personalInfo.address.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.address),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    pw.SizedBox(height: 14),
                    _photoTemplateSectionTitle('SKILLS', _navy,
                        dividerColor: _line, fontSize: 9),
                    pw.Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: resume.skills.take(6).map((skill) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFD7DEE8),
                            borderRadius:
                                pw.BorderRadius.all(pw.Radius.circular(10)),
                          ),
                          child: pw.Text(_sanitizePdfText(skill.name),
                              style: const pw.TextStyle(
                                  fontSize: 7.2, color: _navyDark)),
                        );
                      }).toList(),
                    ),
                    if (resume.certifications.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _photoTemplateSectionTitle('CERTIFICATIONS', _navy,
                          dividerColor: _line, fontSize: 9),
                      ...resume.certifications.take(2).map(
                            (cert) => _photoTemplateCertificationItem(
                              cert,
                              titleColor: _navyDark,
                              bodyColor: _muted,
                            ),
                          ),
                    ],
                    if (resume.languages.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _photoTemplateSectionTitle('LANGUAGES', _navy,
                          dividerColor: _line, fontSize: 9),
                      ...resume.languages.take(2).map(
                            (language) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '${_sanitizePdfText(language.name)}  ${_sanitizePdfText(language.proficiency)}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: const pw.BoxDecoration(color: _paper),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(
                                    resume.personalInfo.fullName.isEmpty
                                        ? 'YOUR NAME'
                                        : resume.personalInfo.fullName)
                                .toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 23,
                              color: _navyDark,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!)
                                    .toUpperCase(),
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            ),
                          pw.Container(
                            height: 1,
                            color: _line,
                            margin: const pw.EdgeInsets.only(top: 8),
                          ),
                        ],
                      ),
                    ),
                    if (resume.objective?.isNotEmpty ?? false) ...[
                      _photoTemplateSectionTitle('ABOUT ME', _navy,
                          dividerColor: _line),
                      pw.Text(
                        _sanitizePdfText(resume.objective!),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _muted,
                          lineSpacing: 1.35,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    if (resume.projects.isNotEmpty) ...[
                      _photoTemplateSectionTitle('PROJECTS', _navy,
                          dividerColor: _line),
                      ...resume.projects.map(
                        (project) => _photoTemplateProjectItem(
                          project,
                          titleColor: _ink,
                          bodyColor: _muted,
                          metaColor: _navyDark,
                        ),
                      ),
                    ],
                    if (resume.experience.isNotEmpty) ...[
                      _photoTemplateSectionTitle('EXPERIENCE', _navy,
                          dividerColor: _line),
                      ...resume.experience.take(3).map(
                            (exp) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          _sanitizePdfText(exp.position),
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      pw.Text(
                                        _formatPhotoTemplateExperienceRange(
                                            exp),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                      _sanitizePdfText(exp.company),
                                      style: const pw.TextStyle(
                                        fontSize: 8.5,
                                        color: _navyDark,
                                      ),
                                    ),
                                  ),
                                  if (exp.description.isNotEmpty)
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(top: 3),
                                      child: pw.Text(
                                        _sanitizePdfText(exp.description),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _muted,
                                          lineSpacing: 1.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.education.isNotEmpty) ...[
                      _photoTemplateSectionTitle('EDUCATION', _navy,
                          dividerColor: _line),
                      ...resume.education.take(2).map(
                            (edu) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          _sanitizePdfText(edu.degree.isEmpty
                                              ? edu.fieldOfStudy
                                              : edu.degree),
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding:
                                              const pw.EdgeInsets.only(top: 2),
                                          child: pw.Text(
                                            _sanitizePdfText(edu.institution),
                                            style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.Text(
                                    _formatPhotoTemplateEducationRange(edu),
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.references.isNotEmpty) ...[
                      _photoTemplateSectionTitle('REFERENCES', _navy,
                          dividerColor: _line),
                      pw.Row(
                        children: resume.references.take(2).map((ref) {
                          return pw.Expanded(
                            child: pw.Container(
                              margin: pw.EdgeInsets.only(
                                  right: ref == resume.references.first ? 6 : 0,
                                  left: ref == resume.references.first ? 0 : 6),
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFF1F4F7),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    _sanitizePdfText(ref.name),
                                    style: pw.TextStyle(
                                      fontSize: 8.8,
                                      color: _ink,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 2),
                                    child: pw.Text(
                                      _sanitizePdfText(
                                          '${ref.position}${ref.company.isNotEmpty ? ' · ${ref.company}' : ''}'),
                                      style: const pw.TextStyle(
                                        fontSize: 7.4,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc;
  }
}

class ElegantDesignTemplate extends PdfTemplate {
  static const _navy = PdfColor.fromInt(0xFF4C596F);
  static const _gold = PdfColor.fromInt(0xFFC9935B);
  static const _paper = PdfColor.fromInt(0xFFF8F5F1);
  static const _sidebar = PdfColor.fromInt(0xFFE6E1DC);
  static const _line = PdfColor.fromInt(0xFFD8C7B4);
  static const _ink = PdfColor.fromInt(0xFF2E3440);
  static const _muted = PdfColor.fromInt(0xFF736B63);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'ED');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 136,
                padding: const pw.EdgeInsets.fromLTRB(14, 16, 14, 14),
                decoration: const pw.BoxDecoration(color: _sidebar),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: _photoTemplateAvatar(
                        photoBytes: photoBytes,
                        initials: initials,
                        size: 68,
                        borderColor: _gold,
                        fillColor: const PdfColor.fromInt(0xFFF3EEE9),
                        textColor: _gold,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    _photoTemplateSectionTitle('CONTACT', _navy,
                        dividerColor: _line, fontSize: 9),
                    if (resume.personalInfo.phone.isNotEmpty)
                      pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                          style:
                              const pw.TextStyle(fontSize: 8, color: _muted)),
                    if (resume.personalInfo.email.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.email),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    if (resume.personalInfo.address.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                            _sanitizePdfText(resume.personalInfo.address),
                            style:
                                const pw.TextStyle(fontSize: 8, color: _muted)),
                      ),
                    pw.SizedBox(height: 14),
                    _photoTemplateSectionTitle('SKILLS', _navy,
                        dividerColor: _line, fontSize: 9),
                    ...resume.skills.take(6).map(
                          (skill) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text('• ${_sanitizePdfText(skill.name)}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted)),
                          ),
                        ),
                    if (resume.certifications.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _photoTemplateSectionTitle('CERTIFICATIONS', _navy,
                          dividerColor: _line, fontSize: 9),
                      ...resume.certifications.take(2).map(
                            (cert) => _photoTemplateCertificationItem(
                              cert,
                              titleColor: _ink,
                              bodyColor: _muted,
                              metaColor: _gold,
                            ),
                          ),
                    ],
                    if (resume.languages.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _photoTemplateSectionTitle('LANGUAGES', _navy,
                          dividerColor: _line, fontSize: 9),
                      ...resume.languages.take(2).map(
                            (language) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '${_sanitizePdfText(language.name)}  ${_sanitizePdfText(language.proficiency)}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted),
                              ),
                            ),
                          ),
                    ],
                    if (resume.references.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      _photoTemplateSectionTitle('REFERENCES', _navy,
                          dividerColor: _line, fontSize: 9),
                      ...resume.references.take(2).map(
                            (ref) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Text(
                                _sanitizePdfText(ref.name),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: _ink,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(resume.personalInfo.fullName.isEmpty
                              ? 'Your Name'
                              : resume.personalInfo.fullName)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 27,
                        color: _navy,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          _sanitizePdfText(resume.personalInfo.jobTitle!)
                              .toUpperCase(),
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: _gold,
                          ),
                        ),
                      ),
                    pw.Container(
                      height: 1,
                      color: _line,
                      margin: const pw.EdgeInsets.only(top: 10, bottom: 14),
                    ),
                    if (resume.objective?.isNotEmpty ?? false) ...[
                      _photoTemplateSectionTitle('ABOUT ME', _navy,
                          dividerColor: _line),
                      pw.Text(
                        _sanitizePdfText(resume.objective!),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _muted,
                          lineSpacing: 1.35,
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    if (resume.projects.isNotEmpty) ...[
                      _photoTemplateSectionTitle('PROJECTS', _navy,
                          dividerColor: _line),
                      ...resume.projects.map(
                        (project) => _photoTemplateProjectItem(
                          project,
                          titleColor: _ink,
                          bodyColor: _muted,
                          metaColor: _gold,
                        ),
                      ),
                    ],
                    if (resume.education.isNotEmpty) ...[
                      _photoTemplateSectionTitle('EDUCATION', _navy,
                          dividerColor: _line),
                      ...resume.education.take(2).map(
                            (edu) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 9),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          _sanitizePdfText(edu.degree.isEmpty
                                              ? edu.fieldOfStudy
                                              : edu.degree),
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding:
                                              const pw.EdgeInsets.only(top: 2),
                                          child: pw.Text(
                                            _sanitizePdfText(edu.institution),
                                            style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.Text(
                                    _formatPhotoTemplateEducationRange(edu),
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: _gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.experience.isNotEmpty) ...[
                      _photoTemplateSectionTitle('EXPERIENCE', _navy,
                          dividerColor: _line),
                      ...resume.experience.take(3).map(
                            (exp) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          _sanitizePdfText(exp.position),
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      pw.Text(
                                        _formatPhotoTemplateExperienceRange(
                                            exp),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                      _sanitizePdfText(exp.company),
                                      style: const pw.TextStyle(
                                        fontSize: 8.5,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                                  if (exp.description.isNotEmpty)
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(top: 3),
                                      child: pw.Text(
                                        _sanitizePdfText(exp.description),
                                        style: const pw.TextStyle(
                                          fontSize: 8,
                                          color: _muted,
                                          lineSpacing: 1.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (resume.references.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _photoTemplateSectionTitle('REFERENCES', _navy,
                          dividerColor: _line),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF4F1ED),
                          border: pw.Border.all(color: _line, width: 1),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < resume.references.take(2).length;
                                index++)
                              pw.Expanded(
                                child: pw.Container(
                                  padding: pw.EdgeInsets.only(
                                    left: index == 0 ? 0 : 8,
                                    right: index == 0 ? 8 : 0,
                                  ),
                                  decoration: index == 0
                                      ? const pw.BoxDecoration(
                                          border: pw.Border(
                                            right: pw.BorderSide(
                                                color: _line, width: 1),
                                          ),
                                        )
                                      : null,
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        _sanitizePdfText(
                                            resume.references[index].name),
                                        style: pw.TextStyle(
                                          fontSize: 8.6,
                                          color: _ink,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.only(top: 2),
                                        child: pw.Text(
                                          _sanitizePdfText(
                                              '${resume.references[index].position}${resume.references[index].company.isNotEmpty ? ' · ${resume.references[index].company}' : ''}'),
                                          style: const pw.TextStyle(
                                            fontSize: 7.4,
                                            color: _muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc;
  }
}

class CreativeProfessionalTemplate extends PdfTemplate {
  static const _teal = PdfColor.fromInt(0xFF2D8C87);
  static const _tealDark = PdfColor.fromInt(0xFF236E6A);
  static const _cream = PdfColor.fromInt(0xFFF1E4D5);
  static const _paper = PdfColor.fromInt(0xFFFFFBF6);
  static const _line = PdfColor.fromInt(0xFFD7C8B8);
  static const _ink = PdfColor.fromInt(0xFF283638);
  static const _muted = PdfColor.fromInt(0xFF6D6D69);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'CP');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) => pw.Container(
          color: _paper,
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: const pw.BoxDecoration(color: _teal),
                child: pw.Row(
                  children: [
                    _photoTemplateAvatar(
                      photoBytes: photoBytes,
                      initials: initials,
                      size: 64,
                      borderColor: PdfColors.white,
                      fillColor: const PdfColor.fromInt(0xFFE8DACC),
                      textColor: _teal,
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _sanitizePdfText(
                                    resume.personalInfo.fullName.isEmpty
                                        ? 'Your Name'
                                        : resume.personalInfo.fullName)
                                .toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 24,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3),
                              child: pw.Text(
                                _sanitizePdfText(resume.personalInfo.jobTitle!),
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColor.fromInt(0xFFD6F0EC),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 160,
                      color: _cream,
                      padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.education.isNotEmpty) ...[
                            _photoTemplateSectionTitle('EDUCATION', _teal,
                                dividerColor: _line, fontSize: 9),
                            ...resume.education.take(2).map(
                                  (edu) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 8),
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          _sanitizePdfText(edu.degree.isEmpty
                                              ? edu.fieldOfStudy
                                              : edu.degree),
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              color: _ink,
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.Text(
                                          _sanitizePdfText(edu.institution),
                                          style: const pw.TextStyle(
                                              fontSize: 8, color: _muted),
                                        ),
                                        pw.Text(
                                          _formatPhotoTemplateEducationRange(
                                              edu),
                                          style: const pw.TextStyle(
                                              fontSize: 7.6, color: _tealDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            pw.SizedBox(height: 8),
                          ],
                          _photoTemplateSectionTitle('SKILLS', _teal,
                              dividerColor: _line, fontSize: 9),
                          ...resume.skills.take(6).map(
                                (skill) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  child: pw.Text(
                                    '• ${_sanitizePdfText(skill.name)}',
                                    style: const pw.TextStyle(
                                        fontSize: 8, color: _muted),
                                  ),
                                ),
                              ),
                          pw.SizedBox(height: 12),
                          _photoTemplateSectionTitle('CONTACT', _teal,
                              dividerColor: _line, fontSize: 9),
                          if (resume.personalInfo.phone.isNotEmpty)
                            pw.Text(_sanitizePdfText(resume.personalInfo.phone),
                                style: const pw.TextStyle(
                                    fontSize: 8, color: _muted)),
                          if (resume.personalInfo.email.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                  _sanitizePdfText(resume.personalInfo.email),
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: _muted)),
                            ),
                          if ((resume.personalInfo.linkedIn ?? '').isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                  _sanitizePdfText(
                                      resume.personalInfo.linkedIn!),
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: _muted)),
                            ),
                          if (resume.personalInfo.address.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                  _sanitizePdfText(resume.personalInfo.address),
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: _muted)),
                            ),
                          if (resume.languages.isNotEmpty) ...[
                            pw.SizedBox(height: 12),
                            _photoTemplateSectionTitle('LANGUAGES', _teal,
                                dividerColor: _line, fontSize: 9),
                            ...resume.languages.take(4).map(
                                  (language) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Text(
                                      '${_sanitizePdfText(language.name)}  ${_sanitizePdfText(language.proficiency)}',
                                      style: const pw.TextStyle(
                                          fontSize: 8, color: _muted),
                                    ),
                                  ),
                                ),
                          ],
                          if (resume.certifications.isNotEmpty) ...[
                            pw.SizedBox(height: 12),
                            _photoTemplateSectionTitle('CERTIFICATIONS', _teal,
                                dividerColor: _line, fontSize: 9),
                            ...resume.certifications.take(2).map(
                                  (cert) => _photoTemplateCertificationItem(
                                    cert,
                                    titleColor: _tealDark,
                                    bodyColor: _muted,
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (resume.objective?.isNotEmpty ?? false) ...[
                              _photoTemplateSectionTitle('ABOUT', _tealDark,
                                  dividerColor: _line),
                              _photoTemplatePrefixedLines(
                                _splitPhotoTemplateText(resume.objective!),
                                prefix: '┃',
                                textColor: _muted,
                                prefixColor: _tealDark,
                                fontSize: 8,
                                spacing: 2,
                              ),
                              pw.SizedBox(height: 12),
                            ],
                            if (resume.experience.isNotEmpty) ...[
                              _photoTemplateSectionTitle(
                                  'EXPERIENCE', _tealDark,
                                  dividerColor: _line),
                              ...resume.experience.take(3).map(
                                    (exp) => pw.Padding(
                                      padding:
                                          const pw.EdgeInsets.only(bottom: 10),
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Row(
                                            mainAxisAlignment: pw
                                                .MainAxisAlignment.spaceBetween,
                                            children: [
                                              pw.Expanded(
                                                child: pw.Text(
                                                  _sanitizePdfText(
                                                      exp.position),
                                                  style: pw.TextStyle(
                                                    fontSize: 10,
                                                    color: _ink,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              pw.Text(
                                                _formatPhotoTemplateExperienceRange(
                                                    exp),
                                                style: const pw.TextStyle(
                                                    fontSize: 8,
                                                    color: _tealDark),
                                              ),
                                            ],
                                          ),
                                          pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                top: 2),
                                            child: pw.Text(
                                              _sanitizePdfText(exp.company),
                                              style: const pw.TextStyle(
                                                  fontSize: 8.4,
                                                  color: _tealDark),
                                            ),
                                          ),
                                          if (exp.description.isNotEmpty)
                                            pw.Padding(
                                              padding: const pw.EdgeInsets.only(
                                                  top: 3),
                                              child: pw.Text(
                                                _sanitizePdfText(
                                                    exp.description),
                                                style: const pw.TextStyle(
                                                  fontSize: 8,
                                                  color: _muted,
                                                  lineSpacing: 1.25,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                            if (resume.projects.isNotEmpty) ...[
                              _photoTemplateSectionTitle('PROJECTS', _tealDark,
                                  dividerColor: _line),
                              ...resume.projects.map(
                                (project) => _photoTemplateProjectItem(
                                  project,
                                  titleColor: _ink,
                                  bodyColor: _muted,
                                  metaColor: _tealDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc;
  }
}

class BluewaveTechTemplate extends PdfTemplate {
  static const _blue = PdfColor.fromInt(0xFF2F66B0);
  static const _blueMid = PdfColor.fromInt(0xFF4D82C8);
  static const _paper = PdfColor.fromInt(0xFFF8FAFE);
  static const _line = PdfColor.fromInt(0xFFD8E5F6);
  static const _ink = PdfColor.fromInt(0xFF20324A);
  static const _muted = PdfColor.fromInt(0xFF657487);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final doc = _buildDocument();
    final photoBytes = _decodeProfilePhoto(resume);
    final initials = _resumeInitials(resume, 'BT');
    final experienceItems = resume.experience;
    final projectItems = resume.projects;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            children: [
              pw.Stack(
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.fromLTRB(20, 22, 100, 22),
                    decoration: const pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [_blue, _blueMid],
                        begin: pw.Alignment.topLeft,
                        end: pw.Alignment.bottomRight,
                      ),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitizePdfText(resume.personalInfo.fullName.isEmpty
                                  ? 'Your Name'
                                  : resume.personalInfo.fullName)
                              .toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 23,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if ((resume.personalInfo.jobTitle ?? '').isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              _sanitizePdfText(resume.personalInfo.jobTitle!)
                                  .toUpperCase(),
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFFDCE8FF),
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Positioned(
                    right: 16,
                    top: 12,
                    child: _photoTemplateAvatar(
                      photoBytes: photoBytes,
                      initials: initials,
                      size: 72,
                      borderColor: PdfColors.white,
                      fillColor: const PdfColor.fromInt(0xFFEAF1FB),
                      textColor: _blue,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ── Left sidebar ───────────────────────────────────────
                    pw.SizedBox(
                      width: 162,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (resume.education.isNotEmpty)
                            _bluewaveCard(
                              title: 'EDUCATION',
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: resume.education.take(2).map((edu) {
                                  return pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 6),
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          _sanitizePdfText(edu.institution),
                                          style: pw.TextStyle(
                                            fontSize: 8.2,
                                            color: _ink,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          _formatPhotoTemplateEducationRange(
                                              edu),
                                          style: const pw.TextStyle(
                                              fontSize: 7.4, color: _muted),
                                        ),
                                        pw.Text(
                                          _sanitizePdfText(edu.degree.isEmpty
                                              ? edu.fieldOfStudy
                                              : edu.degree),
                                          style: const pw.TextStyle(
                                              fontSize: 7.4, color: _muted),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (resume.certifications.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            _bluewaveCard(
                              title: 'CERTIFICATIONS',
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: resume.certifications
                                    .take(2)
                                    .map(
                                      (cert) => _photoTemplateCertificationItem(
                                        cert,
                                        titleColor: _ink,
                                        bodyColor: _muted,
                                        metaColor: _blue,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 8),
                          // ── CONTACT (with LinkedIn, GitHub, Website) ────
                          _bluewaveCard(
                            title: 'CONTACT',
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (resume.personalInfo.phone.isNotEmpty)
                                  pw.Text(
                                      _sanitizePdfText(
                                          resume.personalInfo.phone),
                                      style: const pw.TextStyle(
                                          fontSize: 7.6, color: _muted)),
                                if (resume.personalInfo.email.isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                        _sanitizePdfText(
                                            resume.personalInfo.email),
                                        style: const pw.TextStyle(
                                            fontSize: 7.6, color: _muted)),
                                  ),
                                if ((resume.personalInfo.linkedIn ?? '')
                                    .isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                        _sanitizePdfText(
                                            resume.personalInfo.linkedIn!),
                                        style: const pw.TextStyle(
                                            fontSize: 7.6, color: _muted)),
                                  ),
                                if ((resume.personalInfo.github ?? '')
                                    .isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                        _sanitizePdfText(
                                            resume.personalInfo.github!),
                                        style: const pw.TextStyle(
                                            fontSize: 7.6, color: _muted)),
                                  ),
                                if ((resume.personalInfo.website ?? '')
                                    .isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                        _sanitizePdfText(
                                            resume.personalInfo.website!),
                                        style: const pw.TextStyle(
                                            fontSize: 7.6, color: _muted)),
                                  ),
                                if (resume.personalInfo.address.isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                        _sanitizePdfText(
                                            resume.personalInfo.address),
                                        style: const pw.TextStyle(
                                            fontSize: 7.6, color: _muted)),
                                  ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _bluewaveCard(
                            title: 'SKILLS',
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: resume.skills.take(4).map((skill) {
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  child: pw.Text(
                                    '• ${_sanitizePdfText(skill.name)}',
                                    style: const pw.TextStyle(
                                        fontSize: 7.6, color: _muted),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // ── LANGUAGES ───────────────────────────────────
                          if (resume.languages.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            _bluewaveCard(
                              title: 'LANGUAGES',
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: resume.languages.take(4).map((lang) {
                                  return pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Text(
                                      '${_sanitizePdfText(lang.name)}  ${_sanitizePdfText(lang.proficiency)}',
                                      style: const pw.TextStyle(
                                          fontSize: 7.6, color: _muted),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    // ── Right column ────────────────────────────────────────
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // ── ABOUT ME with ► bullet points ────────────────
                          if (resume.objective?.isNotEmpty ?? false)
                            _bluewaveCard(
                              title: 'ABOUT ME',
                              wide: true,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children:
                                    _splitPhotoTemplateText(resume.objective!)
                                        .map((line) {
                                  return pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 8,
                                          height: 8,
                                          margin: const pw.EdgeInsets.only(
                                              right: 5, top: 2),
                                          child: pw.CustomPaint(
                                            size: const PdfPoint(8, 8),
                                            painter: (canvas, size) {
                                              canvas.setFillColor(_blue);
                                              canvas.moveTo(0, 0);
                                              canvas.lineTo(7, 4);
                                              canvas.lineTo(0, 8);
                                              canvas.closePath();
                                              canvas.fillPath();
                                            },
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            _sanitizePdfText(line),
                                            style: const pw.TextStyle(
                                              fontSize: 8.2,
                                              color: _muted,
                                              lineSpacing: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          // ── EXPERIENCE (before PROJECTS) ─────────────────
                          if (resume.experience.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            _bluewaveCard(
                              title: 'EXPERIENCE',
                              wide: true,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: experienceItems.map((exp) {
                                  final detailLines =
                                      exp.achievements.isNotEmpty
                                          ? exp.achievements
                                              .map(_sanitizePdfText)
                                              .where((line) => line.isNotEmpty)
                                              .toList()
                                          : _splitPhotoTemplateText(
                                              exp.description);
                                  return pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 8),
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Row(
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.spaceBetween,
                                          children: [
                                            pw.Expanded(
                                              child: pw.Text(
                                                _sanitizePdfText(exp.position),
                                                style: pw.TextStyle(
                                                  fontSize: 9.3,
                                                  color: _ink,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            pw.Text(
                                              _formatPhotoTemplateExperienceRange(
                                                  exp),
                                              style: const pw.TextStyle(
                                                  fontSize: 7.4, color: _muted),
                                            ),
                                          ],
                                        ),
                                        pw.Text(
                                          _sanitizePdfText(exp.company),
                                          style: const pw.TextStyle(
                                              fontSize: 8, color: _blue),
                                        ),
                                        if (detailLines.isNotEmpty)
                                          pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                top: 2),
                                            child: _photoTemplatePrefixedLines(
                                              detailLines,
                                              prefix: '▍',
                                              textColor: _muted,
                                              prefixColor: _blue,
                                              fontSize: 7.4,
                                              spacing: 1.2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          if (projectItems.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            _bluewaveCard(
                              title: 'PROJECTS',
                              wide: true,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: projectItems
                                    .map(
                                      (project) => _photoTemplateProjectItem(
                                        project,
                                        titleColor: _ink,
                                        bodyColor: _muted,
                                        metaColor: _blue,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc;
  }

  pw.Widget _bluewaveCard({
    required String title,
    required pw.Widget child,
    bool wide = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: wide ? 9.2 : 8.6,
              color: _blue,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
          pw.Container(
              height: 1,
              color: _line,
              margin: const pw.EdgeInsets.only(top: 3, bottom: 5)),
          child,
        ],
      ),
    );
  }
}

/// A unique, fresher-oriented template with a scholarly aesthetic.
///
/// Design hallmarks:
/// - Warm ivory page background with a narrow accent stripe down the left edge
/// - Name displayed in generous small-caps tracking above a thin double rule
/// - Contact row separated by mid-dots
/// - Section headers use a small filled square marker aligned with the left
///   stripe, plus a dashed underline — a pattern not used by any other template
/// - Education is rendered prominently with institution, degree, GPA row, and
///   optional coursework/description
/// - Skills rendered as compact inline tags
/// - Projects get their own mini-card treatment
/// - Generous whitespace and readable 10-11pt body text
class AcademicTemplate extends PdfTemplate {
  static const _pageBg = PdfColor.fromInt(0xFFFAF8F5);
  static const _ink = PdfColor.fromInt(0xFF2D2D2D);
  static const _muted = PdfColor.fromInt(0xFF555555);
  static const _light = PdfColor.fromInt(0xFF999999);
  static const _rule = PdfColor.fromInt(0xFFCCCCCC);

  @override
  Future<pw.Document> generate(ResumeModel resume, PdfColor accentColor) async {
    _pdfLang = resume.writingLanguage;
    await _loadUnicodeFontIfNeeded();
    final pdf = _buildDocument();
    final sectionOrder = await _loadPdfSectionOrder(resume);

    // --- build section map ------------------------------------------------
    final sections = <String, List<pw.Widget>>{};

    if (resume.objective?.isNotEmpty ?? false) {
      sections['summary'] = [
        _acSectionHeader('CAREER OBJECTIVE', accentColor),
        ..._acSummaryBullets(resume.objective!, accentColor),
        pw.SizedBox(height: 14),
      ];
    }

    if (resume.education.isNotEmpty) {
      sections['education'] = [
        _acSectionHeader('EDUCATION', accentColor),
        ...resume.education.map((edu) => _acEducation(edu, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.skills.isNotEmpty) {
      sections['skills'] = [
        _acSectionHeader('SKILLS', accentColor),
        pw.Wrap(
          spacing: 6,
          runSpacing: 5,
          children: resume.skills.map((s) {
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accentColor, width: 0.7),
              ),
              child: pw.Text(
                _sanitizePdfText(s.name),
                style: const pw.TextStyle(fontSize: 9, color: _ink),
              ),
            );
          }).toList(),
        ),
        pw.SizedBox(height: 14),
      ];
    }

    if (resume.projects.isNotEmpty) {
      sections['projects'] = [
        _acSectionHeader('PROJECTS', accentColor),
        ...resume.projects.map((p) => _acProject(p, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.experience.isNotEmpty) {
      sections['experience'] = [
        _acSectionHeader('EXPERIENCE', accentColor),
        ...resume.experience.map((exp) => _acExperience(exp, accentColor)),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.certifications.isNotEmpty) {
      sections['certifications'] = [
        _acSectionHeader('CERTIFICATIONS', accentColor),
        ...resume.certifications.map((c) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('\u2013 ',
                      style: pw.TextStyle(fontSize: 10, color: accentColor)),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: _sanitizePdfText(c.name),
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink),
                          ),
                          if (c.issuer.isNotEmpty)
                            pw.TextSpan(
                              text: '  -  ${_sanitizePdfText(c.issuer)}',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
        pw.SizedBox(height: 10),
      ];
    }

    if (resume.languages.isNotEmpty) {
      sections['languages'] = [
        _acSectionHeader('LANGUAGES', accentColor),
        pw.Wrap(
          spacing: 16,
          runSpacing: 4,
          children: resume.languages
              .map((l) => pw.Text(
                    '${_sanitizePdfText(l.name)}  (${_sanitizePdfText(l.proficiency)})',
                    style: const pw.TextStyle(fontSize: 10, color: _muted),
                  ))
              .toList(),
        ),
        pw.SizedBox(height: 10),
      ];
    }

    // --- page layout -------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 42, 36),
        build: (context) => [
          _acHeader(resume, accentColor),
          pw.SizedBox(height: 22),
          ..._applyPdfSectionOrder(sectionOrder, sections),
        ],
      ),
    );

    return pdf;
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  pw.Widget _acHeader(ResumeModel resume, PdfColor accent) {
    final name = _sanitizePdfText(
      resume.personalInfo.fullName.isEmpty
          ? 'Your Name'
          : resume.personalInfo.fullName,
    );
    final title = resume.personalInfo.jobTitle?.isNotEmpty == true
        ? _sanitizePdfText(resume.personalInfo.jobTitle!)
        : null;

    final contactParts = <String>[
      if (resume.personalInfo.email.isNotEmpty) resume.personalInfo.email,
      if (resume.personalInfo.phone.isNotEmpty) resume.personalInfo.phone,
      if (resume.personalInfo.address.isNotEmpty) resume.personalInfo.address,
      if (resume.personalInfo.linkedIn?.isNotEmpty ?? false)
        resume.personalInfo.linkedIn!,
      if (resume.personalInfo.website?.isNotEmpty ?? false)
        resume.personalInfo.website!,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: 18, height: 3, color: accent),
        pw.SizedBox(height: 8),
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 2.4,
          ),
        ),
        if (title != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              color: accent,
              letterSpacing: 0.6,
            ),
          ),
        ],
        pw.SizedBox(height: 7),
        // double-rule
        pw.Container(height: 0.8, color: _ink),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.4, color: _rule),
        pw.SizedBox(height: 7),
        if (contactParts.isNotEmpty)
          pw.Text(
            contactParts.map(_sanitizePdfText).join('   |   '),
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
      ],
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────
  pw.Widget _acSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 7, height: 7, color: accent),
              pw.SizedBox(width: 7),
              pw.Text(
                _h(title),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(height: 0.6, color: _rule),
              ),
              pw.SizedBox(width: 8),
              pw.Container(width: 24, height: 1.4, color: accent),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Summary bullets ─────────────────────────────────────────────────────
  List<pw.Widget> _acSummaryBullets(String text, PdfColor accent) {
    final normalized = _sanitizePdfText(text);
    final lines = normalized
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final segments = lines.isNotEmpty
        ? lines
        : normalized
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
    if (segments.isEmpty) return const [];

    return segments.map((line) {
      final clean = line.replaceFirst(RegExp(r'^[-*\u2022]\s*'), '');
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5, left: 14),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3.5),
              child: pw.Container(width: 4, height: 4, color: accent),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Text(
                clean,
                style: const pw.TextStyle(
                    fontSize: 10, lineSpacing: 1.5, color: _muted),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─── Education ────────────────────────────────────────────────────────────
  pw.Widget _acEducation(Education edu, PdfColor accent) {
    final start = DateFormat('MMM yyyy').format(edu.startDate);
    final end = edu.isCurrentlyStudying
        ? _present()
        : DateFormat('MMM yyyy').format(edu.endDate ?? edu.startDate);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, left: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(edu.institution),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink),
                ),
              ),
              pw.Text(
                '$start - $end',
                style: const pw.TextStyle(fontSize: 9, color: _light),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _sanitizePdfText(
              edu.degree.isNotEmpty ? edu.degree : edu.fieldOfStudy,
            ),
            style: pw.TextStyle(fontSize: 10, color: accent),
          ),
          if (edu.fieldOfStudy.isNotEmpty && edu.degree.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              _sanitizePdfText(edu.fieldOfStudy),
              style: const pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ],
          if ((edu.grade ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                  text: 'Grade: ',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink),
                ),
                pw.TextSpan(
                  text: _sanitizePdfText(edu.grade!),
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ]),
            ),
          ],
          if ((edu.description ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              _sanitizePdfText(edu.description!),
              style: const pw.TextStyle(
                  fontSize: 9, color: _muted, lineSpacing: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Experience ───────────────────────────────────────────────────────────
  pw.Widget _acExperience(Experience exp, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, left: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(exp.position),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink),
                ),
              ),
              pw.Text(
                '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.isCurrentlyWorking ? _present() : DateFormat('MMM yyyy').format(exp.endDate!)}',
                style: const pw.TextStyle(fontSize: 9, color: _light),
              ),
            ],
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            _sanitizePdfText(
              '${exp.company}${(exp.location ?? '').isNotEmpty ? '  -  ${exp.location}' : ''}',
            ),
            style: pw.TextStyle(fontSize: 10, color: accent),
          ),
          if (_collectExperienceLines(exp).isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ..._collectExperienceLines(exp).map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('\u2013 ',
                        style: pw.TextStyle(fontSize: 9, color: accent)),
                    pw.Expanded(
                      child: pw.Text(line,
                          style: const pw.TextStyle(
                              fontSize: 9.5, lineSpacing: 1.4, color: _muted)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Project ──────────────────────────────────────────────────────────────
  pw.Widget _acProject(Project project, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9, left: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _sanitizePdfText(project.title),
            style: pw.TextStyle(
                fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
          if (project.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _sanitizePdfText(project.description),
              style: const pw.TextStyle(
                  fontSize: 9.5, lineSpacing: 1.4, color: _muted),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Wrap(
              spacing: 5,
              runSpacing: 3,
              children: project.technologies.map((t) {
                return pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _pageBg,
                    border: pw.Border.all(color: accent, width: 0.5),
                  ),
                  child: pw.Text(
                    _sanitizePdfText(t),
                    style: pw.TextStyle(fontSize: 8, color: accent),
                  ),
                );
              }).toList(),
            ),
          ],
          if ((project.url ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _sanitizePdfText(project.url!),
              style: pw.TextStyle(
                fontSize: 8.5,
                color: accent,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PdfTemplateFactory {
  static PdfTemplate getTemplate(String templateId) {
    switch (templateId) {
      case 'modern':
        return ModernNovaPdfTemplate();

      case 'startup':
        return StartupTemplate();

      case 'developer':
        return DeveloperResumePdfTemplate();

      case 'creative':
        return CreativeResumePdfTemplate();

      case 'professional':
        return ProfessionalResumePdfTemplate();

      case 'modern_aesthetic':
        return ModernAestheticTemplate();

      case 'classic_ats':
        return ClassicAtsResumePdfTemplate();

      case 'classic2':
        return ClassicPlusResumePdfTemplate();

      case 'education_resume':
        return EducationResumePdfTemplate();

      case 'modern_resume':
        return EliteResumePdfTemplate();

      case 'professional_accountant':
        return ProfessionalAccountantResumePdfTemplate();

      case 'one_page_resume':
        return OnePageResumePdfTemplate();

      case 'classic_temp':
        return ClassicTempResumePdfTemplate();

      case 'classic':
        return ClassicResumePdfTemplate();

      case 'executive':
        return BusinessManagementResumePdfTemplate();

      case 'sales':
        return SalesAndMarketingResumePdfTemplate();

      case 'academic':
        return AcademicResumePdfTemplate();

      case 'two_column':
        return TwoColumnResumePdfTemplate();

      case 'infographic':
        return InfographicResumePdfTemplate();

      case 'elegant_pink':
        return PinkRoseModernPdfTemplate();

      case 'multicolor':
        return MulticolorTemplate();

      case 'blue_gray':
        return FlexColorSidebarPdfTemplate();

      case 'cool_blue':
        return CoolBlueTemplate();

      case 'mono_nova':
        return MonoNovaResumePdfTemplate();

      case 'slate_arc':
        return SlateArcResumePdfTemplate();

      case 'editorial_frame':
        return EditorialFrameResumePdfTemplate();

      case 'graphite_column':
        return GraphiteColumnResumePdfTemplate();

      case 'rosewood_panel':
        return RosewoodPanelResumePdfTemplate();

      case 'designer_profile':
        return DesignerProfileResumePdfTemplate();

      case 'modern_edge':
        return ModernEdgeResumePdfTemplate();

      case 'minimal_clean':
        return MinimalCleanResumePdfTemplate();

      case 'minimal_clean_ats':
        return MinimalCleanAtsResumePdfTemplate();

      case 'professional_tone':
        return HealthcareResumePdfTemplate();

      case 'elegant_design':
        return ElegantDesignResumePdfTemplate();

      case 'creative_professional':
        return CreativeProfessionalResumePdfTemplate();

      case 'bluewave_tech':
        return BluewaveTechResumePdfTemplate();

      case 'balanced_two_column_layout':
        return BalancedTwoColumnLayoutTemplate();

      case 'elegant_gold_layout':
        return ElegantGoldLayoutTemplate();

      case 'corporate_navy':
        return CorporateNavyResumePdfTemplate();

      case 'forest_edge_classic':
        return ForestEdgeClassicResumePdfTemplate();

      case 'forest_edge':
        return ForestEdgeResumePdfTemplate();

      case 'emerald_executive':
        return EmeraldExecutiveResumePdfTemplate();

      case 'entry_level':
        return EntryLevelResumePdfTemplate();

      case 'ats_optimized_clean':
        return AtsOptimizedCleanResumePdfTemplate();

      case 'ats_standard_format':
        return AtsStandardFormatTemplate();

      case 'ats_friendly_modern':
        return AtsFriendlyModernResumePdfTemplate();

      case 'executive_classic':
        return ExecutiveClassicResumePdfTemplate();

      case 'vertical_timeline':
        return VerticalTimelineTemplate();

      case 'corporate_template':
        return CorporateResumePdfTemplate();

      case 'minimal':
        return MinimalResumePdfTemplate();

      default:
        return MinimalTemplate();
    }
  }
}
