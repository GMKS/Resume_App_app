import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/saved_resume.dart';

class ModernPdfExporter {
  static Future<Uint8List> build(SavedResume resume) async {
    final d = resume.data;
    final info = (d['personalInfo'] is Map)
        ? Map<String, dynamic>.from(d['personalInfo'])
        : <String, dynamic>{};

    // Read personal info from either nested map or top-level keys for compatibility
    final name = (info['name'] ?? d['name'] ?? '').toString();
    final email = (info['email'] ?? d['email'] ?? '').toString();
    final phone = (info['phone'] ?? d['phone'] ?? '').toString();
    final linkedIn =
        (info['linkedin'] ??
                info['linkedIn'] ??
                d['linkedin'] ??
                d['linkedIn'] ??
                '')
            .toString();
    final photoB64 =
        (info['profilePhotoBase64'] ?? d['profilePhotoBase64'] ?? '')
            .toString();
    // Prefer generic 'summary', but fallback to other template-specific keys
    final summary =
        (d['summary'] ??
                d['executiveSummary'] ??
                d['professionalSummary'] ??
                d['creativeSummary'] ??
                '')
            .toString();
    final jobTitle = (d['jobTitle'] ?? '').toString();
    final skills = _extractSkills(d);
    List<Map<String, dynamic>> work = (d['workExperience'] is List)
        ? List<Map<String, dynamic>>.from(d['workExperience'])
        : <Map<String, dynamic>>[];
    if (work.isEmpty && d['workExperiences'] is String) {
      try {
        final list = jsonDecode(d['workExperiences']) as List<dynamic>;
        work = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .map(
              (m) => {
                'role': (m['jobTitle'] ?? '').toString(),
                'company': (m['company'] ?? '').toString(),
                'start': null,
                'end': null,
                'description': (m['description'] ?? '').toString(),
              },
            )
            .toList();
      } catch (_) {}
    }
    List<Map<String, dynamic>> education = (d['education'] is List)
        ? List<Map<String, dynamic>>.from(d['education'])
        : <Map<String, dynamic>>[];
    if (education.isEmpty && d['educations'] is String) {
      try {
        final list = jsonDecode(d['educations']) as List<dynamic>;
        education = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .map(
              (m) => {
                'degree': (m['degree'] ?? '').toString(),
                'school': (m['institution'] ?? '').toString(),
                'start': null,
                'end': null,
                'description': (m['description'] ?? '').toString(),
              },
            )
            .toList();
      } catch (_) {}
    }
    final certifications = (d['certifications'] ?? '').toString();
    final achievements = (d['achievements'] ?? '').toString();
    final hobbies = (d['hobbies'] ?? '').toString();

    final doc = pw.Document();

    pw.Widget? photoWidget;
    if (photoB64.isNotEmpty) {
      try {
        final idx = photoB64.indexOf(',');
        final raw = idx > 0 ? photoB64.substring(idx + 1) : photoB64;
        final bytes = base64Decode(raw);
        final image = pw.MemoryImage(bytes);
        photoWidget = pw.Container(
          width: 56,
          height: 56,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover),
          ),
        );
      } catch (_) {}
    }

    pw.TextStyle h1 = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle h2 = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
      decoration: pw.TextDecoration.underline,
    );
    pw.TextStyle body = const pw.TextStyle(fontSize: 10);

    pw.Widget sectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(title, style: h2),
    );

    pw.Widget bullet(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: body),
          pw.Expanded(child: pw.Text(text, style: body)),
        ],
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header row with photo + name/summary
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (photoWidget != null) ...[
                    photoWidget,
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          name.isEmpty ? resume.title : name.toUpperCase(),
                          style: h1,
                        ),
                        if (jobTitle.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            jobTitle,
                            style: body.copyWith(
                              fontSize: 11,
                              color: PdfColors.grey800,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                        if (summary.isNotEmpty) ...[
                          pw.SizedBox(height: 6),
                          pw.Text('PROFESSIONAL SUMMARY', style: h2),
                          pw.SizedBox(height: 4),
                          pw.Text(summary, style: body),
                        ],
                        pw.SizedBox(height: 8),
                        pw.Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (email.isNotEmpty)
                              pw.Row(
                                children: [
                                  pw.Text('✉ ', style: body),
                                  pw.Text(email, style: body),
                                ],
                              ),
                            if (phone.isNotEmpty)
                              pw.Row(
                                children: [
                                  pw.Text('☎ ', style: body),
                                  pw.Text(phone, style: body),
                                ],
                              ),
                            if (linkedIn.isNotEmpty)
                              pw.UrlLink(
                                destination: linkedIn.startsWith('http')
                                    ? linkedIn
                                    : 'https://$linkedIn',
                                child: pw.Row(
                                  children: [
                                    pw.Text('in ', style: body),
                                    pw.Text(
                                      linkedIn,
                                      style: body.copyWith(
                                        color: PdfColors.blue,
                                      ),
                                    ),
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
              pw.SizedBox(height: 14),

              // Two columns body
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionTitle('WORK EXPERIENCE'),
                        for (final w in work) ...[
                          _jobBlock(w, body),
                          if ((w['description'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                top: 3,
                                left: 8,
                              ),
                              child: pw.Text(
                                (w['description'] ?? '').toString(),
                                style: body,
                              ),
                            ),
                          if (w['bullets'] is List)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                top: 3,
                                left: 4,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: List.from(w['bullets'])
                                    .map((b) => b.toString())
                                    .where((t) => t.trim().isNotEmpty)
                                    .map(
                                      (t) => pw.Row(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text('•  ', style: body),
                                          pw.Expanded(
                                            child: pw.Text(t, style: body),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          pw.SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionTitle('EDUCATION'),
                        for (final e in education) ...[
                          _eduBlock(e, body),
                          if ((e['description'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                top: 3,
                                left: 8,
                              ),
                              child: pw.Text(
                                (e['description'] ?? '').toString(),
                                style: body,
                              ),
                            ),
                          pw.SizedBox(height: 6),
                        ],
                        pw.SizedBox(height: 8),
                        if (skills.isNotEmpty) ...[
                          sectionTitle('SKILLS'),
                          for (final s in skills) bullet(s),
                          pw.SizedBox(height: 8),
                        ],
                        if (certifications.isNotEmpty) ...[
                          sectionTitle('CERTIFICATIONS'),
                          for (final c
                              in certifications
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty))
                            bullet(c),
                          pw.SizedBox(height: 8),
                        ],
                        if (achievements.isNotEmpty) ...[
                          sectionTitle('ACHIEVEMENTS'),
                          for (final a
                              in achievements
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty))
                            bullet(a),
                          pw.SizedBox(height: 8),
                        ],
                        if (d['customFields'] is List &&
                            (d['customFields'] as List).isNotEmpty) ...[
                          sectionTitle('ADDITIONAL INFORMATION'),
                          for (final cf in (d['customFields'] as List))
                            bullet(cf.toString()),
                          pw.SizedBox(height: 8),
                        ],
                        if (hobbies.isNotEmpty) ...[
                          sectionTitle('HOBBIES'),
                          for (final h
                              in hobbies
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty))
                            bullet(h),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static List<String> _extractSkills(Map<String, dynamic> data) {
    final v = data['skills'];
    if (v is List) {
      if (v.isEmpty) return _skillsFromCsv(data);
      if (v.first is String) {
        return v.cast<String>();
      }
      if (v.first is Map) {
        return v
            .map((e) => (e['label'] ?? e['name'] ?? e.toString()).toString())
            .cast<String>()
            .toList();
      }
      return v.map((e) => e.toString()).cast<String>().toList();
    }
    // For Professional template, support 'keySkills' as a CSV list
    final keySkills = (data['keySkills'] ?? '').toString();
    if (keySkills.isNotEmpty) {
      return keySkills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // Classic/Minimal often store skills as a comma-separated string in 'skills'
    final simpleSkills = (data['skills'] ?? '').toString();
    if (simpleSkills.isNotEmpty) {
      return simpleSkills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // Creative may include 'tools' alongside 'skills'
    final tools = (data['tools'] ?? '').toString();
    final combined = <String>[];
    if (tools.isNotEmpty) {
      combined.addAll(
        tools.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }
    if (combined.isNotEmpty) return combined;
    return _skillsFromCsv(data);
  }

  static List<String> _skillsFromCsv(Map<String, dynamic> data) {
    final csv = (data['skillsCsv'] ?? '').toString();
    if (csv.isEmpty) return const [];
    return csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _dateRange(dynamic startIso, dynamic endIso) {
    String fmt(dynamic iso) {
      if (iso == null) return '';
      try {
        final dt = DateTime.tryParse(iso.toString());
        if (dt == null) return '';
        final m = dt.month.toString().padLeft(2, '0');
        return '${dt.year}-$m';
      } catch (_) {
        return '';
      }
    }

    final s = fmt(startIso);
    final e = fmt(endIso);
    if (s.isEmpty && e.isEmpty) return '';
    return e.isEmpty ? '$s - Present' : '$s - $e';
  }

  static pw.Widget _jobBlock(Map<String, dynamic> w, pw.TextStyle body) {
    final role = (w['role'] ?? '').toString();
    final company = (w['company'] ?? '').toString();
    final dr = _dateRange(w['start'], w['end']);
    final location = (w['location'] ?? '').toString();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          role,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        if (company.isNotEmpty) pw.Text(company, style: body),
        pw.Row(
          children: [
            if (dr.isNotEmpty) pw.Text(dr, style: body),
            if (dr.isNotEmpty && location.isNotEmpty) pw.SizedBox(width: 12),
            if (location.isNotEmpty) pw.Text(location, style: body),
          ],
        ),
      ],
    );
  }

  static pw.Widget _eduBlock(Map<String, dynamic> e, pw.TextStyle body) {
    final degree = (e['degree'] ?? '').toString();
    final school = (e['school'] ?? '').toString();
    final college = (e['college'] ?? '').toString();
    final dr = _dateRange(e['start'], e['end']);
    final location = (e['location'] ?? '').toString();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (degree.isNotEmpty)
          pw.Text(
            degree,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        if (school.isNotEmpty) pw.Text(school, style: body),
        if (college.isNotEmpty) pw.Text(college, style: body),
        pw.Row(
          children: [
            if (dr.isNotEmpty) pw.Text(dr, style: body),
            if (dr.isNotEmpty && location.isNotEmpty) pw.SizedBox(width: 12),
            if (location.isNotEmpty) pw.Text(location, style: body),
          ],
        ),
      ],
    );
  }
}
