import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/saved_resume.dart';

class OnePagePdfExporter {
  static Future<Uint8List> build(SavedResume resume) async {
    final data = resume.data;

    String t(String k) => (data[k] ?? '').toString();

    // Contact
    final name = t('name');
    final title = t('title');
    final email = t('email');
    final phone = t('phone');
    final linkedIn = t('linkedIn').isNotEmpty ? t('linkedIn') : t('linkedin');

    // Profile
    final summary = t('summary');

    // Sidebar sections
    final skillsCsv = t('coreSkills');
    final awards = t('awards');
    final languages = t('languages');

    // Decode image if present
    pw.Widget photo() {
      final b64 = t('profilePhotoBase64');
      if (b64.isEmpty) return pw.SizedBox();
      try {
        final bytes = base64Decode(b64);
        return pw.Container(
          width: 90,
          height: 90,
          // Removed unsupported clipBehavior/shape for pdf package
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
        );
      } catch (_) {
        return pw.SizedBox();
      }
    }

    List<Map<String, dynamic>> decodeListPrefer(
      String primary,
      String fallbackJson,
      String fallbackList,
    ) {
      final primaryStr = t(primary);
      if (primaryStr.isNotEmpty) {
        try {
          return (jsonDecode(primaryStr) as List)
              .cast<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        } catch (_) {}
      }
      final fb = t(fallbackJson);
      if (fb.isNotEmpty) {
        try {
          return (jsonDecode(fb) as List)
              .cast<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        } catch (_) {}
      }
      final arr = data[fallbackList];
      if (arr is List) {
        return arr
            .cast<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
      return const [];
    }

    // Date range helper that supports multiple key variants used across the app
    String dateRange(Map e) {
      String pick(List<String> keys) {
        for (final k in keys) {
          final v = e[k];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
        return '';
      }

      String fmt(String s) {
        if (s.isEmpty) return '';
        // Expect ISO or yyyy-MM; keep it short to yyyy-MM
        return s.length >= 7 ? s.substring(0, 7) : s;
      }

      final startRaw = pick(['startDate', 'start', 'from']);
      final endRaw = pick(['endDate', 'end', 'to']);
      final s = fmt(startRaw);
      final ed = fmt(endRaw);
      if (s.isEmpty && ed.isEmpty) return '';
      if (ed.isEmpty) return '$s – Present';
      if (s.isEmpty) return ed;
      return '$s – $ed';
    }

    final work = decodeListPrefer(
      'workExperiencesJson',
      'workExperiences',
      'workExperience',
    );
    final edu = decodeListPrefer('educationsJson', 'educations', 'education');

    List<String> splitCsv(String val) =>
        val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final skills = splitCsv(skillsCsv);

    pw.Widget h(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            t.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          pw.Container(height: 1, color: PdfColors.grey600),
        ],
      ),
    );

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left rail
              pw.Container(
                width: 220,
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    photo(),
                    if (email.isNotEmpty ||
                        phone.isNotEmpty ||
                        linkedIn.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      h('Contact'),
                      if (phone.isNotEmpty)
                        pw.Text(phone, style: const pw.TextStyle(fontSize: 9)),
                      if (email.isNotEmpty)
                        pw.Text(email, style: const pw.TextStyle(fontSize: 9)),
                      // Add portfolio to match preview
                      if (t('portfolio').isNotEmpty)
                        pw.Text(
                          t('portfolio'),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (linkedIn.isNotEmpty)
                        pw.UrlLink(
                          destination: linkedIn.startsWith('http')
                              ? linkedIn
                              : 'https://$linkedIn',
                          child: pw.Text(
                            linkedIn,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.blue,
                            ),
                          ),
                        ),
                    ],
                    if (edu.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      h('Education'),
                      ...edu.map((e) {
                        final degree = (e['degree'] ?? '').toString();
                        final institution =
                            (e['institution'] ?? e['university'] ?? '')
                                .toString();
                        final range = dateRange(e);
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (degree.isNotEmpty)
                                pw.Text(
                                  degree,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              if (institution.isNotEmpty)
                                pw.Text(
                                  institution,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              if (range.isNotEmpty)
                                pw.Text(
                                  range,
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (skills.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      h('Skills'),
                      ...skills.map(
                        (s) => pw.Bullet(
                          text: s,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                    if (awards.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      h('Awards'),
                      // Split comma-separated awards into bullets to mirror preview
                      ...awards
                          .split(',')
                          .map((a) => a.trim())
                          .where((a) => a.isNotEmpty)
                          .map(
                            (a) => pw.Text(
                              '• $a',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                    ],
                    if (languages.isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      h('Languages'),
                      pw.Text(
                        languages,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
              // Main panel
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Top banner to more closely match preview styling
                      pw.Container(
                        width: double.infinity,
                        color: PdfColors.lightBlue,
                        padding: const pw.EdgeInsets.fromLTRB(20, 24, 20, 18),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty)
                              pw.Text(
                                name.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              )
                            else
                              pw.Text(
                                ((resume.title.isNotEmpty
                                        ? resume.title
                                        : 'RESUME'))
                                    .toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            if (title.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Text(
                                  title,
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Content area with proper padding
                      pw.Container(
                        padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (summary.isNotEmpty) ...[
                              h('Profile'),
                              pw.Text(
                                summary,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.SizedBox(height: 12),
                            ],
                            if (work.isNotEmpty) ...[
                              h('Professional Experience'),
                              ...work.map((w) {
                                final role = (w['jobTitle'] ?? w['role'] ?? '')
                                    .toString();
                                final company = (w['company'] ?? '').toString();
                                final location = (w['location'] ?? '')
                                    .toString();
                                final range = dateRange(w);
                                final desc = (w['description'] ?? '')
                                    .toString();
                                final bullets = (w['achievements'] is List)
                                    ? (w['achievements'] as List)
                                          .map((e) => e.toString())
                                          .toList()
                                    : const <String>[];

                                return pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 12),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        role.isNotEmpty ? role : company,
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (company.isNotEmpty ||
                                          range.isNotEmpty ||
                                          location.isNotEmpty)
                                        pw.Text(
                                          [
                                            if (company.isNotEmpty) company,
                                            if (location.isNotEmpty) location,
                                            if (range.isNotEmpty) range,
                                          ].join(' • '),
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.grey700,
                                          ),
                                        ),
                                      if (desc.isNotEmpty)
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: pw.Text(
                                            desc,
                                            style: const pw.TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      if (bullets.isNotEmpty)
                                        ...bullets.map(
                                          (b) => pw.Bullet(
                                            text: b,
                                            style: const pw.TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
