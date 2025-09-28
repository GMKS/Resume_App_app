import 'dart:io';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/premium_service.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Export service that generates simple ATS-friendly outputs.
/// PDF generation is implemented with a minimal, dependency-free PDF writer
/// that produces a valid single-page PDF using Helvetica.
class ShareExportService {
  ShareExportService._();
  static final ShareExportService instance = ShareExportService._();

  /// Generate an ATS-friendly PDF file and return it. The PDF uses a
  /// single-page, single-font (Helvetica) layout with plain text headings
  /// and bullets for maximal ATS compatibility.
  Future<File> exportAndOpenPdf(SavedResume resume) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${_sanitize(resume.title)}_$ts.pdf';
    final file = File('${Directory.systemTemp.path}/$fileName');

    final lines = _buildAtsLines(resume);
    final pdfBytes = _buildMinimalPdf(lines);
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  /// Create a fake DOCX file (really just text content with .docx extension).
  Future<File> exportDoc(SavedResume resume) async {
    return _writeTempText(
      resume,
      extension: 'docx',
      header: 'DOCX (placeholder)\n',
    );
  }

  /// Create a TXT export with plain-text representation.
  Future<File> exportTxt(SavedResume resume) async {
    return _writeTempText(resume, extension: 'txt', header: 'TXT Export\n');
  }

  // --- Premium-only Share Helpers ---
  Future<void> shareViaEmail(SavedResume resume) async {
    if (!PremiumService.isPremium) {
      throw Exception('Email sharing is a Premium feature.');
    }
    final file = await exportAndOpenPdf(resume);
    final subject = 'Resume - ${resume.title}';
    final text = 'Please find my resume attached.';
    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'application/pdf',
          name: file.uri.pathSegments.last,
        ),
      ],
      subject: subject,
      text: text,
    );
  }

  Future<void> shareViaWhatsApp(SavedResume resume) async {
    if (!PremiumService.isPremium) {
      throw Exception('WhatsApp sharing is a Premium feature.');
    }
    final file = await exportAndOpenPdf(resume);
    // share_plus will open the system share sheet, allowing WhatsApp selection
    await Share.shareXFiles([
      XFile(
        file.path,
        mimeType: 'application/pdf',
        name: file.uri.pathSegments.last,
      ),
    ], text: 'Sharing my resume: ${resume.title}');
  }

  // --- Minimal PDF generator (single page, Helvetica, ASCII only) ---
  // This writer constructs a tiny valid PDF by hand. It renders the provided
  // lines using a fixed 12pt font, wrapping long lines approximately.
  List<int> _buildMinimalPdf(List<String> lines) {
    // PDF page size A4 in points (72 dpi): 595 x 842
    const pageWidth = 595;
    const pageHeight = 842;
    const marginLeft = 50;
    const marginTop = 50;
    const fontSize = 12;
    const leading = 16; // line height

    // Wrap lines to a rough character width to avoid overflow.
    // This is an approximation; Helvetica ~ 0.5 width factor per char at 12pt.
    // With margins, usable width ~ 495. At 12pt, ~ 95 chars max. Use 90.
    final wrapped = <String>[];
    for (final l in lines) {
      final ascii = _toAscii(l);
      if (ascii.length <= 90) {
        wrapped.add(ascii);
      } else {
        wrapped.addAll(_wrapByChars(ascii, 90));
      }
    }

    // Build content stream (text drawing commands)
    final buffer = StringBuffer();
    buffer.writeln('BT');
    buffer.writeln('/F1 $fontSize Tf');
    buffer.writeln('$leading TL');
    // Start at (marginLeft, pageHeight - marginTop)
    buffer.writeln('1 0 0 1 $marginLeft ${pageHeight - marginTop} Tm');
    for (var i = 0; i < wrapped.length; i++) {
      final txt = _pdfEscape(wrapped[i]);
      if (i == 0) {
        buffer.writeln('($txt) Tj');
      } else {
        buffer.writeln('T*'); // move down by leading
        buffer.writeln('($txt) Tj');
      }
    }
    buffer.writeln('ET');
    final content = buffer.toString();
    final contentBytes = utf8.encode(content);

    // Build PDF objects, track byte offsets
    final out = BytesBuilder();
    final offsets = <int>[];

    void write(String s) => out.add(utf8.encode(s));

    write('%PDF-1.4\n');

    // 1: Catalog
    offsets.add(out.length);
    write('1 0 obj\n');
    write('<< /Type /Catalog /Pages 2 0 R >>\n');
    write('endobj\n');

    // 2: Pages
    offsets.add(out.length);
    write('2 0 obj\n');
    write('<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n');
    write('endobj\n');

    // 3: Page
    offsets.add(out.length);
    write('3 0 obj\n');
    write('<< /Type /Page /Parent 2 0 R ');
    write('/MediaBox [0 0 $pageWidth $pageHeight] ');
    write('/Resources << /Font << /F1 4 0 R >> >> ');
    write('/Contents 5 0 R >>\n');
    write('endobj\n');

    // 4: Font (Helvetica)
    offsets.add(out.length);
    write('4 0 obj\n');
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n');
    write('endobj\n');

    // 5: Contents stream
    offsets.add(out.length);
    write('5 0 obj\n');
    write('<< /Length ${contentBytes.length} >>\n');
    write('stream\n');
    out.add(contentBytes);
    write('\nendstream\n');
    write('endobj\n');

    // xref
    final xrefStart = out.length;
    write('xref\n');
    write('0 6\n');
    write('0000000000 65535 f \n');
    for (final off in offsets) {
      final line = off.toString().padLeft(10, '0');
      write('$line 00000 n \n');
    }

    // trailer
    write('trailer\n');
    write('<< /Size 6 /Root 1 0 R >>\n');
    write('startxref\n');
    write('$xrefStart\n');
    write('%%EOF');

    return out.takeBytes();
  }

  // Build ATS-friendly content lines from resume data
  List<String> _buildAtsLines(SavedResume resume) {
    final d = resume.data;
    // final bool atsOn = (d['ats_friendly']?.toString().toLowerCase() == 'true');

    final lines = <String>[];
    String name = (d['name'] ?? '').toString().trim();
    String email = (d['email'] ?? '').toString().trim();
    String phone = (d['phone'] ?? '').toString().trim();
    String summary = (d['summary'] ?? '').toString().trim();
    String skills = (d['skills'] ?? '').toString().trim();
    String certs = (d['certifications'] ?? '').toString().trim();

    if (name.isNotEmpty) lines.add(_asciiSafe(name.toUpperCase()));
    final contact = [
      if (email.isNotEmpty) email,
      if (phone.isNotEmpty) phone,
    ].where((e) => e.isNotEmpty).join(' | ');
    if (contact.isNotEmpty) lines.add(_asciiSafe(contact));
    if (lines.isNotEmpty) lines.add('');

    if (summary.isNotEmpty) {
      lines.add('PROFESSIONAL SUMMARY');
      lines.addAll(_wrapByChars(_asciiSafe(summary), 90));
      lines.add('');
    }

    if (skills.isNotEmpty) {
      lines.add('SKILLS');
      final items = skills
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        for (final s in items) {
          lines.add('- ${_asciiSafe(s)}');
        }
        lines.add('');
      }
    }

    // Work Experiences (JSON string in classic form)
    if ((d['workExperiences'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['workExperiences']) as List<dynamic>;
        if (list.isNotEmpty) {
          lines.add('WORK EXPERIENCE');
          for (final item in list) {
            final m = Map<String, dynamic>.from(item as Map);
            final title = (m['jobTitle'] ?? '').toString().trim();
            final company = (m['company'] ?? '').toString().trim();
            final desc = (m['description'] ?? '').toString().trim();
            final heading = [
              title,
              if (company.isNotEmpty) 'at $company',
            ].where((e) => e.isNotEmpty).join(' ');
            if (heading.isNotEmpty) lines.add('- ${_asciiSafe(heading)}');
            if (desc.isNotEmpty) {
              for (final w in _wrapByChars(_asciiSafe(desc), 86)) {
                lines.add('  $w');
              }
            }
          }
          lines.add('');
        }
      } catch (_) {}
    }

    // Education (JSON string in classic form)
    if ((d['educations'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['educations']) as List<dynamic>;
        if (list.isNotEmpty) {
          lines.add('EDUCATION');
          for (final item in list) {
            final m = Map<String, dynamic>.from(item as Map);
            final degree = (m['degree'] ?? '').toString().trim();
            final inst = (m['institution'] ?? '').toString().trim();
            final desc = (m['description'] ?? '').toString().trim();
            final heading = [
              degree,
              if (inst.isNotEmpty) 'at $inst',
            ].where((e) => e.isNotEmpty).join(' ');
            if (heading.isNotEmpty) lines.add('- ${_asciiSafe(heading)}');
            if (desc.isNotEmpty) {
              for (final w in _wrapByChars(_asciiSafe(desc), 86)) {
                lines.add('  $w');
              }
            }
          }
          lines.add('');
        }
      } catch (_) {}
    }

    if (certs.isNotEmpty) {
      lines.add('CERTIFICATIONS');
      for (final w in _wrapByChars(_asciiSafe(certs), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    // Optional watermark for free tier
    if (PremiumService.hasWatermark) {
      lines.add('');
      lines.add('Generated with Resume Builder (Free tier)');
    }

    // atsOn is currently always "on" in Classic; kept for future styling
    return lines;
  }

  // --- Helpers ---
  Future<File> _writeTempText(
    SavedResume resume, {
    required String extension,
    String header = '',
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${_sanitize(resume.title)}_$ts.$extension';
    final file = File('${Directory.systemTemp.path}/$fileName');
    final content = StringBuffer()
      ..writeln(header)
      ..writeln('Title: ${resume.title}')
      ..writeln('Template: ${resume.template}')
      ..writeln('Created: ${resume.createdAt.toIso8601String()}')
      ..writeln('Updated: ${resume.updatedAt.toIso8601String()}')
      ..writeln('--- Data ---')
      ..writeln(const JsonEncoder.withIndent('  ').convert(resume.data));
    await file.writeAsString(content.toString());
    return file;
  }

  String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_').trim();
  }

  // Ensure ASCII to keep PDF content simple and widely compatible.
  String _toAscii(String input) {
    final sb = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      if (codeUnit >= 32 && codeUnit <= 126) {
        sb.writeCharCode(codeUnit);
      } else {
        sb.write('?');
      }
    }
    return sb.toString();
  }

  String _asciiSafe(String input) => _toAscii(input).replaceAll('\u2022', '-');

  // Escape parentheses and backslashes for PDF string literals.
  String _pdfEscape(String text) {
    return text
        .replaceAll('\\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  List<String> _wrapByChars(String text, int maxChars) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = StringBuffer();
    for (final w in words) {
      if (current.isEmpty) {
        current.write(w);
      } else if ((current.length + 1 + w.length) <= maxChars) {
        current.write(' ');
        current.write(w);
      } else {
        lines.add(current.toString());
        current = StringBuffer(w);
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());
    return lines;
  }
}
