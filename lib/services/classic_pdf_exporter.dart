import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/saved_resume.dart';
import '../models/branding.dart';

class ClassicPdfExporter {
  static Future<Uint8List> build(SavedResume resume) async {
    // Load Roboto fonts via PdfGoogleFonts and build themed document
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
      ),
    );

    final data = Map<String, dynamic>.from(resume.data);
    String val(String k) => (data[k] ?? '').toString().trim();
    String or(List<String> keys) {
      for (final k in keys) {
        final v = val(k);
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final fullName = or(['full_name', 'name']);
    final title = or(['title', 'professionalTitle']);
    final email = val('email');
    final phone = val('phone');
    final portfolio = or(['portfolio', 'website']);
    final linkedin = or(['linkedIn', 'linkedin']);

    List<Map<String, dynamic>> parseJsonArray(String key) {
      final raw = data[key];
      if (raw == null) return [];
      try {
        final list = jsonDecode(raw.toString()) as List<dynamic>;
        return list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {
        return [];
      }
    }

    String fmtRange(String startIso, String endIso) {
      String fmt(String iso) {
        if (iso.isEmpty) return '';
        final dt = DateTime.tryParse(iso);
        if (dt == null) return '';
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      }

      final s = fmt(startIso);
      final e = fmt(endIso);
      if (s.isEmpty && e.isEmpty) return '';
      return e.isEmpty ? '$s – Present' : '$s – $e';
    }

    final summary = or(['summary', 'executiveSummary']);
    // Strengths can be a comma/newline separated string
    final strengthsRaw = val('strengths');
    final strengths = strengthsRaw
        .split(RegExp('[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final skillsCsv = or(['skills', 'skillsCsv']);
    final certificationsCsv = val('certifications');
    final work = parseJsonArray('workExperiences').isNotEmpty
        ? parseJsonArray('workExperiences')
        : parseJsonArray('workExperiencesJson');
    final edus = parseJsonArray('educations');

    pw.Widget sectionHeader(String text) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: PdfColors.grey400),
      ],
    );

    List<pw.Widget> experienceBlocks() {
      return work.map((w) {
        String v(String k) => (w[k] ?? '').toString();
        final title = v('jobTitle');
        final company = v('company');
        final location = v('location');
        final start = v('startDate');
        final end = v('endDate');
        final range = fmtRange(start, end);
        final desc = v('description');
        final ach = (w['achievements'] is List)
            ? List.from(w['achievements'])
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toList()
            : const <String>[];
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (company.isNotEmpty) pw.Text(company),
              pw.Row(
                children: [
                  if (range.isNotEmpty) pw.Text(range),
                  if (range.isNotEmpty && location.isNotEmpty)
                    pw.SizedBox(width: 12),
                  if (location.isNotEmpty) pw.Text(location),
                ],
              ),
              if (desc.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(desc)],
              if (ach.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: ach
                      .map(
                        (a) => pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• '),
                            pw.Expanded(child: pw.Text(a)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      }).toList();
    }

    List<pw.Widget> educationBlocks() {
      return edus.map((e) {
        String v(String k) => (e[k] ?? '').toString();
        final degree = v('degree');
        final inst = v('institution');
        final location = v('location');
        final gpa = v('gpa');
        final start = v('startDate');
        final end = v('endDate');
        final range = fmtRange(start, end);
        final desc = v('description');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                degree,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (inst.isNotEmpty) pw.Text(inst),
              pw.Row(
                children: [
                  if (range.isNotEmpty) pw.Text(range),
                  if (range.isNotEmpty && location.isNotEmpty)
                    pw.SizedBox(width: 12),
                  if (location.isNotEmpty) pw.Text(location),
                ],
              ),
              if (gpa.isNotEmpty) pw.Text('GPA: $gpa'),
              if (desc.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text(desc)],
            ],
          ),
        );
      }).toList();
    }

    // Resolve branding-driven accent color (used for subtitle)
    PdfColor pdfColorFromHex(String hex) {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) {
        final r = int.tryParse(h.substring(0, 2), radix: 16) ?? 0;
        final g = int.tryParse(h.substring(2, 4), radix: 16) ?? 0;
        final b = int.tryParse(h.substring(4, 6), radix: 16) ?? 0;
        return PdfColor(r / 255.0, g / 255.0, b / 255.0);
      }
      return PdfColors.blue800;
    }

    PdfColor brandAccent = PdfColors.blue800;
    try {
      final brandingJson = data['branding'];
      if (brandingJson != null && brandingJson.toString().isNotEmpty) {
        final branding = BrandingTheme.fromJson(
          jsonDecode(brandingJson.toString()) as Map<String, dynamic>,
        );
        brandAccent = pdfColorFromHex(branding.accentColor);
      }
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        build: (context) {
          final blocks = <pw.Widget>[];

          // Header
          blocks.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  fullName.isEmpty ? resume.title : fullName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: PdfColors.black,
                  ),
                ),
                if (title.isNotEmpty)
                  pw.Text(
                    title,
                    style: pw.TextStyle(color: brandAccent, fontSize: 12),
                  ),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    if (phone.isNotEmpty) pw.Text(phone),
                    if (phone.isNotEmpty && email.isNotEmpty) pw.Text('•'),
                    if (email.isNotEmpty) pw.Text(email),
                    if ((email.isNotEmpty &&
                            (portfolio.isNotEmpty || linkedin.isNotEmpty)) ||
                        (phone.isNotEmpty &&
                            (portfolio.isNotEmpty || linkedin.isNotEmpty)))
                      pw.Text('•'),
                    if (portfolio.isNotEmpty) pw.Text(portfolio),
                    if (portfolio.isNotEmpty && linkedin.isNotEmpty)
                      pw.Text('•'),
                    if (linkedin.isNotEmpty) pw.Text(linkedin),
                  ],
                ),
              ],
            ),
          );

          // Summary
          if (summary.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 16));
            blocks.add(sectionHeader('Summary'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.add(
              pw.Text(summary, style: const pw.TextStyle(height: 1.3)),
            );
          }

          // Strengths
          if (strengths.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 14));
            blocks.add(sectionHeader('Strengths'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: strengths
                    .map(
                      (s) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• '),
                            pw.Expanded(
                              child: pw.Text(
                                s,
                                style: const pw.TextStyle(height: 1.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }

          // Experience
          if (work.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 16));
            blocks.add(sectionHeader('Experience'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.addAll(experienceBlocks());
          }

          // Education
          if (edus.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 14));
            blocks.add(sectionHeader('Education'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.addAll(educationBlocks());
          }

          // Skills
          if (skillsCsv.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 14));
            blocks.add(sectionHeader('Skills'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.add(
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skillsCsv
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .map(
                      (s) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          s,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }

          // Certifications
          if (certificationsCsv.isNotEmpty) {
            blocks.add(pw.SizedBox(height: 14));
            blocks.add(sectionHeader('Certifications'));
            blocks.add(pw.SizedBox(height: 6));
            blocks.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: certificationsCsv
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .map(
                      (c) => pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• '),
                          pw.Expanded(
                            child: pw.Text(
                              c,
                              style: const pw.TextStyle(height: 1.25),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            );
          }

          return blocks;
        },
      ),
    );

    return pdf.save();
  }
}
