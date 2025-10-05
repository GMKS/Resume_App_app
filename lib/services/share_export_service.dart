import 'dart:io';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/premium_service.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'modern_pdf_exporter.dart';
import 'one_page_pdf_exporter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart' as ar;
import 'package:url_launcher/url_launcher.dart';

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
    final outDir = await _getExportBaseDir();
    final file = File(
      p.join(outDir.path, '${_sanitize(resume.title)}_$ts.pdf'),
    );

    // If explicitly marked ATS-friendly, use minimal writer; otherwise use styled exporter for all templates
    final atsFriendly =
        (resume.data['ats_friendly'] ?? '').toString() == 'true';
    if (!atsFriendly) {
      // Route One Page to its dedicated exporter to match UI preview
      final lower = resume.template.toLowerCase();
      final bytes = lower == 'one page'
          ? await OnePagePdfExporter.build(resume)
          : await ModernPdfExporter.build(resume);
      await file.writeAsBytes(bytes, flush: true);
    } else {
      final lines = _buildAtsLines(resume);
      final pdfBytes = _buildMinimalPdf(lines);
      await file.writeAsBytes(pdfBytes, flush: true);
    }
    return file;
  }

  /// Create a valid DOCX (WordprocessingML) that mirrors the ATS-friendly content.
  Future<File> exportDoc(SavedResume resume) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outDir = await _getExportBaseDir();
    final file = File(
      p.join(outDir.path, '${_sanitize(resume.title)}_$ts.docx'),
    );
    final lines = _buildAtsLines(resume);
    final bytes = _buildDocxFromLines(lines);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Create a TXT export with plain-text representation.
  Future<File> exportTxt(SavedResume resume) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outDir = await _getExportBaseDir();
    final file = File(
      p.join(outDir.path, '${_sanitize(resume.title)}_$ts.txt'),
    );
    final content = _buildAtsLines(resume).join('\n');
    await file.writeAsString(content);
    return file;
  }

  // --- Premium-only Share Helpers ---
  Future<void> shareViaEmail(SavedResume resume) async {
    print(
      'DEBUG: shareViaEmail called. Premium status: ${PremiumService.isPremium}',
    );
    if (!PremiumService.isPremium) {
      print('DEBUG: Premium check failed, throwing exception');
      throw Exception('Email sharing is a Premium feature.');
    }
    print('DEBUG: Starting PDF export for email share');
    final file = await exportAndOpenPdf(resume);
    print('DEBUG: PDF exported to: ${file.path}');
    final shareFile = await _copyToShareCache(file);
    print('DEBUG: Share file copied to cache: ${shareFile.path}');
    final subject = 'Resume - ${resume.title}';
    const text = 'Please find my resume attached.';
    try {
      print('DEBUG: Attempting share via Share.shareXFiles');
      await Share.shareXFiles(
        [
          XFile(
            shareFile.path,
            mimeType: 'application/pdf',
            name: shareFile.uri.pathSegments.last,
          ),
        ],
        subject: subject,
        text: text,
      );
      print('DEBUG: Share.shareXFiles completed successfully');
    } catch (e) {
      print('DEBUG: Share.shareXFiles failed: $e');
      final uri = Uri(
        scheme: 'mailto',
        queryParameters: {'subject': subject, 'body': text},
      );
      print('DEBUG: Attempting fallback mailto: $uri');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('DEBUG: Mailto fallback launched');
      } else {
        print('DEBUG: Mailto fallback not available');
      }
    }
  }

  Future<void> shareViaWhatsApp(SavedResume resume) async {
    print(
      'DEBUG: shareViaWhatsApp called. Premium status: ${PremiumService.isPremium}',
    );
    if (!PremiumService.isPremium) {
      print('DEBUG: Premium check failed, throwing exception');
      throw Exception('WhatsApp sharing is a Premium feature.');
    }
    print('DEBUG: Starting PDF export for WhatsApp share');
    final file = await exportAndOpenPdf(resume);
    print('DEBUG: PDF exported to: ${file.path}');
    final shareFile = await _copyToShareCache(file);
    print('DEBUG: Share file copied to cache: ${shareFile.path}');
    // share_plus will open the system share sheet, allowing WhatsApp selection
    try {
      print('DEBUG: Attempting share via Share.shareXFiles');
      await Share.shareXFiles([
        XFile(
          shareFile.path,
          mimeType: 'application/pdf',
          name: shareFile.uri.pathSegments.last,
        ),
      ], text: 'Sharing my resume: ${resume.title}');
      print('DEBUG: Share.shareXFiles completed successfully');
    } catch (e) {
      print('DEBUG: Share.shareXFiles failed: $e');
      final text = Uri.encodeComponent('Sharing my resume: ${resume.title}');
      final uri = Uri.parse('whatsapp://send?text=$text');
      print('DEBUG: Attempting WhatsApp fallback: $uri');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('DEBUG: WhatsApp fallback launched');
      } else {
        print('DEBUG: WhatsApp not available, trying web fallback');
        final web = Uri.parse('https://wa.me/?text=$text');
        if (await canLaunchUrl(web)) {
          await launchUrl(web, mode: LaunchMode.externalApplication);
          print('DEBUG: Web fallback launched');
        } else {
          print('DEBUG: No WhatsApp fallback available');
        }
      }
    }
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
    final lines = <String>[];

    // Personal info: support both flat and nested structures
    final info = (d['personalInfo'] is Map)
        ? Map<String, dynamic>.from(d['personalInfo'])
        : <String, dynamic>{};
    String name = (info['name'] ?? d['name'] ?? '').toString().trim();
    String email = (info['email'] ?? d['email'] ?? '').toString().trim();
    String phone = (info['phone'] ?? d['phone'] ?? '').toString().trim();
    // Accept both linkedIn and linkedin keys
    String linkedIn =
        (info['linkedin'] ??
                info['linkedIn'] ??
                d['linkedIn'] ??
                d['linkedin'] ??
                '')
            .toString()
            .trim();
    String portfolio = (d['portfolio'] ?? info['portfolio'] ?? '')
        .toString()
        .trim();
    String summary = (d['summary'] ?? '').toString().trim();

    if (name.isNotEmpty) lines.add(_asciiSafe(name.toUpperCase()));
    final contact = [
      if (email.isNotEmpty) 'Email: $email',
      if (phone.isNotEmpty) 'Phone: $phone',
      if (linkedIn.isNotEmpty) 'LinkedIn: $linkedIn',
      if (portfolio.isNotEmpty) 'Portfolio: $portfolio',
    ].where((e) => e.isNotEmpty).join(' | ');
    if (contact.isNotEmpty) lines.add(_asciiSafe(contact));
    if (lines.isNotEmpty) lines.add('');

    if (summary.isNotEmpty) {
      lines.add('PROFESSIONAL SUMMARY');
      lines.addAll(_wrapByChars(_asciiSafe(summary), 90));
      lines.add('');
    }

    // Skills: list, list of maps, or csv fallback; for One Page prefer coreSkills
    final skillsList = _extractSkills(d);
    if (skillsList.isNotEmpty) {
      lines.add('SKILLS');
      for (final s in skillsList) {
        lines.add('- ${_asciiSafe(s)}');
      }
      lines.add('');
    }

    // Work Experience: prefer modern array, fallback to classic JSON string
    List<Map<String, dynamic>> work = (d['workExperience'] is List)
        ? List<Map<String, dynamic>>.from(d['workExperience'])
        : <Map<String, dynamic>>[];
    // One Page stores JSON in workExperiencesJson
    if (work.isEmpty &&
        (d['workExperiencesJson'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['workExperiencesJson']) as List<dynamic>;
        work = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    if (work.isNotEmpty) {
      lines.add('WORK EXPERIENCE');
      for (final w in work) {
        final role = (w['jobTitle'] ?? w['role'] ?? '').toString().trim();
        final company = (w['company'] ?? '').toString().trim();
        final start = (w['startDate'] ?? w['start'] ?? '').toString();
        final end = (w['endDate'] ?? w['end'] ?? '').toString();
        final dr = _dateRange(start, end);
        final heading = [
          role,
          if (company.isNotEmpty) 'at $company',
          if (dr.isNotEmpty) '($dr)',
        ].where((e) => e.isNotEmpty).join(' ');
        if (heading.isNotEmpty) lines.add('- ${_asciiSafe(heading)}');
        final desc = (w['description'] ?? '').toString().trim();
        if (desc.isNotEmpty) {
          for (final w in _wrapByChars(_asciiSafe(desc), 86)) {
            lines.add('  $w');
          }
        }
      }
      lines.add('');
    } else if ((d['workExperiences'] ?? '').toString().isNotEmpty) {
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

    // Education: prefer modern array, fallback to classic JSON string
    List<Map<String, dynamic>> edu = (d['education'] is List)
        ? List<Map<String, dynamic>>.from(d['education'])
        : <Map<String, dynamic>>[];
    if (edu.isEmpty && (d['educationsJson'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['educationsJson']) as List<dynamic>;
        edu = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    if (edu.isNotEmpty) {
      lines.add('EDUCATION');
      for (final e in edu) {
        final degree = (e['degree'] ?? '').toString().trim();
        final school =
            (e['school'] ?? e['institution'] ?? e['university'] ?? '')
                .toString()
                .trim();
        final dr = _dateRange(
          (e['startDate'] ?? e['start'] ?? '').toString(),
          (e['endDate'] ?? e['end'] ?? '').toString(),
        );
        final heading = [
          degree,
          if (school.isNotEmpty) 'at $school',
          if (dr.isNotEmpty) '($dr)',
        ].where((x) => x.isNotEmpty).join(' ');
        if (heading.isNotEmpty) lines.add('- ${_asciiSafe(heading)}');
      }
      lines.add('');
    } else if ((d['educations'] ?? '').toString().isNotEmpty) {
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

    final certs = (d['certifications'] ?? '').toString().trim();
    if (certs.isNotEmpty) {
      lines.add('CERTIFICATIONS');
      for (final w in _wrapByChars(_asciiSafe(certs), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    final projects = (d['projects'] ?? '').toString().trim();
    if (projects.isNotEmpty) {
      lines.add('PROJECTS');
      for (final w in _wrapByChars(_asciiSafe(projects), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    final hobbies = (d['hobbies'] ?? '').toString().trim();
    if (hobbies.isNotEmpty) {
      lines.add('HOBBIES');
      for (final w in _wrapByChars(_asciiSafe(hobbies), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    final achievements = (d['achievements'] ?? '').toString().trim();
    if (achievements.isNotEmpty) {
      lines.add('ACHIEVEMENTS');
      for (final w in _wrapByChars(_asciiSafe(achievements), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    // One Page extras
    final awards = (d['awards'] ?? '').toString().trim();
    if (awards.isNotEmpty) {
      lines.add('AWARDS');
      for (final a
          in awards
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)) {
        lines.add('- ${_asciiSafe(a)}');
      }
      lines.add('');
    }

    final languages = (d['languages'] ?? '').toString().trim();
    if (languages.isNotEmpty) {
      lines.add('LANGUAGES');
      for (final w in _wrapByChars(_asciiSafe(languages), 90)) {
        lines.add('- $w');
      }
      lines.add('');
    }

    // Optional watermark for free tier
    if (PremiumService.hasWatermark) {
      lines.add('');
      lines.add('Generated with Resume Builder (Free tier)');
    }

    return lines;
  }

  // Helper: accept skills in multiple shapes
  List<String> _extractSkills(Map<String, dynamic> data) {
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
    return _skillsFromCsv(data);
  }

  List<String> _skillsFromCsv(Map<String, dynamic> data) {
    // Prefer One Page key 'coreSkills', fallback to generic 'skillsCsv'
    final csv = ((data['coreSkills'] ?? data['skillsCsv']) ?? '').toString();
    if (csv.isEmpty) return const [];
    return csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Compact date range from ISO strings (YYYY-MM)
  String _dateRange(String startIso, String endIso) {
    String fmt(String iso) {
      if (iso.isEmpty) return '';
      try {
        final dt = DateTime.tryParse(iso);
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

  // --- Helpers ---
  // --- Export directory helper (user-visible Resumes folder) ---
  Future<Directory> _getExportBaseDir() async {
    Directory base;
    if (Platform.isAndroid) {
      base =
          (await getExternalStorageDirectory()) ??
          await getTemporaryDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final out = Directory(p.join(base.path, 'Resumes'));
    if (!await out.exists()) {
      await out.create(recursive: true);
    }
    return out;
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

  /// Copy file into a cache directory for sharing to ensure FileProvider-accessible URI
  Future<File> _copyToShareCache(File file) async {
    final cache = await getTemporaryDirectory();
    final shareDir = Directory(p.join(cache.path, 'share-cache'));
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    final dest = File(p.join(shareDir.path, p.basename(file.path)));
    if (await dest.exists()) {
      await dest.delete();
    }
    return file.copy(dest.path);
  }

  // ===================== DOCX helpers (WordprocessingML) =====================

  Uint8List _buildDocxFromLines(List<String> lines) {
    final zip = ar.Archive();
    zip.addFile(ar.ArchiveFile.string('[Content_Types].xml', _contentTypesXml));
    zip.addFile(ar.ArchiveFile.string('_rels/.rels', _relsXml));
    zip.addFile(ar.ArchiveFile.string('docProps/app.xml', _appPropsXml));
    zip.addFile(ar.ArchiveFile.string('docProps/core.xml', _corePropsXml));
    zip.addFile(ar.ArchiveFile.string('word/styles.xml', _stylesXml));
    zip.addFile(ar.ArchiveFile.string('word/settings.xml', _settingsXml));
    zip.addFile(
      ar.ArchiveFile.string('word/_rels/document.xml.rels', _wordRelsXml),
    );
    zip.addFile(
      ar.ArchiveFile.string('word/document.xml', _buildDocXmlFromLines(lines)),
    );
    final bytes = ar.ZipEncoder().encode(zip)!;
    return Uint8List.fromList(bytes);
  }

  String _buildDocXmlFromLines(List<String> lines) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final parts = lines
        .map((l) => l.trimRight())
        .map(
          (l) =>
              '<w:p><w:r><w:rPr><w:noProof/></w:rPr><w:t>${esc(l)}</w:t></w:r></w:p>',
        )
        .join();
    return '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $parts
  </w:body>
</w:document>''';
  }

  // OOXML static parts
  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
</Types>''';

  static const String _relsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const String _wordRelsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
</Relationships>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="character" w:default="1" w:styleId="DefaultParagraphFont">
    <w:name w:val="Default Paragraph Font"/>
  </w:style>
</w:styles>''';

  static const String _settingsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:proofState w:spelling="clean" w:grammar="clean"/>
</w:settings>''';

  static const String _appPropsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Resume Builder</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <Company></Company>
</Properties>''';

  static const String _corePropsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Resume</dc:title>
  <dc:subject></dc:subject>
  <dc:creator>Resume Builder</dc:creator>
  <cp:keywords>resume</cp:keywords>
  <cp:lastModifiedBy>Resume Builder</cp:lastModifiedBy>
</cp:coreProperties>''';
}
