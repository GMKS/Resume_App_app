import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive/archive.dart' as ar;

import '../models/saved_resume.dart';
import '../services/ai_service.dart';
import 'one_page_pdf_exporter.dart';
import 'colorful_minimal_pdf_exporter.dart';
import 'classic_pdf_exporter.dart';
import 'professional_pdf_exporter.dart';
import 'premium_service.dart';
import 'ai_service.dart';

class ShareExportService {
  final BuildContext context;
  ShareExportService(this.context);

  Future<void> shareViaEmail(SavedResume resume) async {
    await _shareResume(
      resume,
      (file, subject, resumeData) =>
          _shareViaEmailInternal(file, subject, resumeData),
    );
  }

  Future<void> shareViaWhatsApp(SavedResume resume) async {
    await _shareResume(
      resume,
      (file, subject, resumeData) =>
          _shareViaWhatsAppInternal(file, subject, resumeData),
    );
  }

  Future<void> _shareResume(
    SavedResume resume,
    Future<void> Function(File, String, Map<String, dynamic>) shareFunction,
  ) async {
    // Ensure a name is available for the fallback "Curriculum Vitae" PDF
    if (resume.template != 'One Page') {
      final ok = await _ensureFullNameIfMissing(resume);
      if (!ok) return; // user cancelled
    }

    File? pdfFile;
    try {
      pdfFile = await _generatePdf(resume);
    } catch (e, s) {
      print('DEBUG: Exception during PDF generation: $e\n$s');
      await _showErrorDialog('Failed to generate PDF for sharing.');
      return;
    }

    if (pdfFile == null) {
      print('DEBUG: PDF generation returned null.');
      await _showErrorDialog('Failed to generate PDF for sharing.');
      return;
    }

    final subject = 'Resume: ${resume.data['full_name'] ?? 'Details'}';
    // Let the inner share function manage its own fallbacks and dialogs.
    await shareFunction(pdfFile, subject, resume.data);
  }

  Future<File?> _generatePdf(SavedResume resume) async {
    // Handle colorful minimal templates
    if (resume.template.startsWith('Minimal-')) {
      try {
        print(
          'DEBUG: Building Colorful Minimal PDF for template "${resume.template}"…',
        );
        final pdf = await ColorfulMinimalPdfExporter.build(resume);
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/colorful_minimal_resume.pdf");
        await file.writeAsBytes(pdf);
        return file;
      } catch (e, s) {
        print('DEBUG: ColorfulMinimalPdfExporter failed: $e\n$s');
        // Fallback to regular minimal PDF
        try {
          return await _generateMinimalPdf(resume);
        } catch (ee, ss) {
          print('DEBUG: Fallback minimal PDF failed: $ee\n$ss');
          return null;
        }
      }
    }

    if (resume.template == 'One Page') {
      try {
        print('DEBUG: Building One Page PDF…');
        final pdf = await OnePagePdfExporter.build(resume);
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/one_page_resume.pdf");
        await file.writeAsBytes(pdf);
        return file;
      } catch (e, s) {
        // Fallback to generic PDF if styled exporter fails for any reason
        print('DEBUG: OnePagePdfExporter failed: $e\n$s');
        try {
          return await _generateFallbackPdf(resume);
        } catch (ee, ss) {
          print(
            'DEBUG: Fallback PDF generation after One Page failure also failed: $ee\n$ss',
          );
          try {
            return await _generateMinimalPdf(resume);
          } catch (eee, sss) {
            print('DEBUG: Minimal PDF generation failed too: $eee\n$sss');
            return null;
          }
        }
      }
    }

    if (resume.template == 'Classic') {
      try {
        final pdf = await ClassicPdfExporter.build(resume);
        final output = await getTemporaryDirectory();
        final file = File(p.join(output.path, 'classic_resume.pdf'));
        await file.writeAsBytes(pdf);
        return file;
      } catch (e, s) {
        print('DEBUG: ClassicPdfExporter failed: $e\n$s');
        // Fallback to generic PDF
        try {
          return await _generateFallbackPdf(resume);
        } catch (ee, ss) {
          print('DEBUG: Fallback after Classic failed: $ee\n$ss');
          return null;
        }
      }
    }

    if (resume.template == 'Professional') {
      try {
        print('DEBUG: Building Professional PDF…');
        final pdf = await ProfessionalPdfExporter.build(resume);
        final output = await getTemporaryDirectory();
        final file = File(p.join(output.path, 'professional_resume.pdf'));
        await file.writeAsBytes(pdf);
        return file;
      } catch (e, s) {
        print('DEBUG: ProfessionalPdfExporter failed: $e\n$s');
        // Fallback to generic PDF
        try {
          return await _generateFallbackPdf(resume);
        } catch (ee, ss) {
          print('DEBUG: Fallback after Professional failed: $ee\n$ss');
          return null;
        }
      }
    }

    // Fallback for other templates
    print(
      'DEBUG: Using fallback PDF generator for template "${resume.template}".',
    );
    try {
      return await _generateFallbackPdf(resume);
    } catch (e, s) {
      print('DEBUG: Generic fallback PDF failed: $e\n$s');
      try {
        return await _generateMinimalPdf(resume);
      } catch (ee, ss) {
        print('DEBUG: Minimal PDF generation also failed: $ee\n$ss');
        return null;
      }
    }
  }

  Future<File> _generateFallbackPdf(SavedResume resume) async {
    // Load readable, modern fonts to better match UI preview
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
    // Some devices may carry unexpected value types; copy defensively.
    final Map<String, dynamic> data = {
      for (final entry in resume.data.entries)
        entry.key.toString(): entry.value,
    };
    const accent = PdfColors.indigo;

    // Reduce unnecessary prompt: derive full_name from 'name' if present
    if ((data['full_name'] == null ||
            data['full_name'].toString().trim().isEmpty) &&
        (data['name'] != null && data['name'].toString().trim().isNotEmpty)) {
      data['full_name'] = data['name'];
    }

    // Specialized formatting for Creative template; mirror preview layout and include photo
    if (resume.template.toLowerCase() == 'creative') {
      final work = _parseJsonArray(data['workExperiences']);
      final edus = _parseJsonArray(data['educations']);
      final skillsCsv = (data['skills'] ?? '').toString();
      final tools = (data['tools'] ?? '').toString();
      final projects = (data['projects'] ?? '').toString();
      final languages = (data['languages'] ?? '').toString();
      final hobbies = (data['hobbies'] ?? '').toString();
      final references = (data['references'] ?? '').toString();
      final photoB64 = (data['profilePhotoBase64'] ?? '').toString();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            // Header: optional photo + name + contact lines
            pw.Widget? photoWidget;
            if (photoB64.isNotEmpty) {
              try {
                print('DEBUG: Processing photo - length: ${photoB64.length}');
                final idx = photoB64.indexOf(',');
                final raw = idx > 0 ? photoB64.substring(idx + 1) : photoB64;
                print('DEBUG: Base64 data after comma: ${raw.length} chars');
                final bytes = base64Decode(raw);
                print('DEBUG: Decoded bytes: ${bytes.length}');
                photoWidget = pw.ClipOval(
                  child: pw.Container(
                    width: 72,
                    height: 72,
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                );
                print('DEBUG: Photo widget created successfully');
              } catch (e, stackTrace) {
                print('DEBUG: Photo decode failed: $e');
                print('DEBUG: Stack trace: $stackTrace');
                print(
                  'DEBUG: PhotoB64 starts with: ${photoB64.substring(0, photoB64.length > 50 ? 50 : photoB64.length)}',
                );
                photoWidget = null;
              }
            }

            final name = (data['full_name'] ?? resume.title).toString();
            final email = (data['email'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();
            final portfolio = (data['portfolio'] ?? '').toString();
            final social = (data['socialLinks'] ?? '').toString();

            final leftCol = <pw.Widget>[];
            final summary = (data['creativeSummary'] ?? '').toString();
            if (summary.isNotEmpty) {
              leftCol.addAll([
                _sectionTitle('Creative Summary', color: accent),
                pw.Text(summary),
                pw.SizedBox(height: 12),
              ]);
            }
            leftCol.add(_sectionTitle('Work Experience', color: accent));
            leftCol.addAll(work.map((w) => _workBlock(w)));
            leftCol.add(pw.SizedBox(height: 10));
            if (projects.isNotEmpty) {
              leftCol.addAll([
                _sectionTitle('Projects', color: accent),
                _bulletsFromCsv(projects, bulletColor: accent),
              ]);
            }

            final rightCol = <pw.Widget>[];
            rightCol.add(_sectionTitle('Education', color: accent));
            rightCol.addAll(edus.map((e) => _eduBlock(e)));
            if (skillsCsv.isNotEmpty) {
              rightCol.addAll([
                pw.SizedBox(height: 10),
                _sectionTitle('Skills', color: accent),
                _bulletsFromCsv(skillsCsv, bulletColor: accent),
              ]);
            }
            if (tools.isNotEmpty) {
              rightCol.addAll([
                pw.SizedBox(height: 10),
                _sectionTitle('Tools & Software', color: accent),
                _bulletsFromCsv(tools, bulletColor: accent),
              ]);
            }
            if (languages.isNotEmpty) {
              rightCol.addAll([
                pw.SizedBox(height: 10),
                _sectionTitle('Languages', color: accent),
                _bulletsFromCsv(languages, bulletColor: accent),
              ]);
            }
            if (hobbies.isNotEmpty) {
              rightCol.addAll([
                pw.SizedBox(height: 10),
                _sectionTitle('Hobbies', color: accent),
                _bulletsFromCsv(hobbies, bulletColor: accent),
              ]);
            }
            if (references.isNotEmpty) {
              rightCol.addAll([
                pw.SizedBox(height: 10),
                _sectionTitle('References', color: accent),
                pw.Text(references),
              ]);
            }

            return [
              // Header
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
                          name,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 26,
                            color: PdfColors.indigo700,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        if (email.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                margin: const pw.EdgeInsets.only(
                                  top: 6,
                                  right: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                              pw.Text(
                                email,
                                style: const pw.TextStyle(
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        if (phone.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                margin: const pw.EdgeInsets.only(
                                  top: 6,
                                  right: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                              pw.Text(
                                phone,
                                style: const pw.TextStyle(
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        if (portfolio.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                margin: const pw.EdgeInsets.only(
                                  top: 6,
                                  right: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                              pw.Text(
                                portfolio,
                                style: const pw.TextStyle(
                                  color: PdfColors.indigo,
                                ),
                              ),
                            ],
                          ),
                        if (social.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                margin: const pw.EdgeInsets.only(
                                  top: 6,
                                  right: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                              pw.Text(
                                social,
                                style: const pw.TextStyle(
                                  color: PdfColors.indigo,
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
              // Two-column content: left 2/3, right 1/3
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 2, child: pw.Column(children: leftCol)),
                  pw.SizedBox(width: 20),
                  pw.Expanded(flex: 1, child: pw.Column(children: rightCol)),
                ],
              ),
            ];
          },
        ),
      );
    } else {
      // Generic fallback: simple key/value listing
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _cvHeader(data['full_name'] ?? resume.title),
            pw.SizedBox(height: 20),
            ...data.entries.map((entry) {
              final v = entry.value?.toString() ?? '';
              if (v.isEmpty) return pw.SizedBox.shrink();
              // Skip bulky raw JSON payloads in generic rendering
              if (_looksLikeJsonArray(v)) return pw.SizedBox.shrink();
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _formatKey(entry.key),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(v),
                  pw.SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      );
    }

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/fallback_resume.pdf");
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e, s) {
      print('DEBUG: Writing fallback PDF failed: $e\n$s');
      rethrow;
    }
  }

  // Minimal last-resort PDF generator that writes plain text lines only
  Future<File> _generateMinimalPdf(SavedResume resume) async {
    print('DEBUG: Generating minimal PDF…');
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: baseFont));
    String safe(String s) => _sanitizeForPdfText(s);
    final content = _buildPlainTextForDoc(resume);
    final lines = content.split(RegExp(r'\r?\n'));
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [for (final l in lines) pw.Text(safe(l))],
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'resume_minimal.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Remove characters that the built-in font can't render to avoid runtime errors
  String _sanitizeForPdfText(String input) {
    final allowed = input.runes.where((c) {
      // keep common ASCII and basic Latin-1 Supplement
      return (c >= 0x20 && c <= 0x7E) || (c >= 0xA0 && c <= 0xFF);
    });
    return String.fromCharCodes(allowed);
  }

  pw.Widget _cvHeader(String title) => pw.Header(
    level: 0,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Curriculum Vitae',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 28,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 22,
            color: PdfColors.indigo,
          ),
        ),
      ],
    ),
  );

  pw.Widget _sectionTitle(String title, {PdfColor color = PdfColors.black}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
            color: color,
          ),
        ),
      );

  pw.Widget _workBlock(Map<String, dynamic> w) {
    String val(String k) => (w[k] ?? '').toString();
    String range() {
      String fmt(String iso) {
        if (iso.isEmpty) return '';
        final dt = DateTime.tryParse(iso);
        if (dt == null) return '';
        final m = dt.month.toString().padLeft(2, '0');
        return '${dt.year}-$m';
      }

      final s = fmt(val('startDate'));
      final e = fmt(val('endDate'));
      if (s.isEmpty && e.isEmpty) return '';
      return e.isEmpty ? '$s - Present' : '$s - $e';
    }

    final bullets = <pw.Widget>[];
    final desc = val('description');
    if (desc.isNotEmpty) bullets.add(pw.Text(desc));
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            val('jobTitle'),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (val('company').isNotEmpty) pw.Text(val('company')),
          pw.Row(
            children: [
              if (range().isNotEmpty) pw.Text(range()),
              if (val('location').isNotEmpty) ...[
                pw.SizedBox(width: 12),
                pw.Text(val('location')),
              ],
            ],
          ),
          if (bullets.isNotEmpty) ...[pw.SizedBox(height: 4), ...bullets],
        ],
      ),
    );
  }

  pw.Widget _eduBlock(Map<String, dynamic> e) {
    String val(String k) => (e[k] ?? '').toString();
    String range() {
      String fmt(String iso) {
        if (iso.isEmpty) return '';
        final dt = DateTime.tryParse(iso);
        if (dt == null) return '';
        final m = dt.month.toString().padLeft(2, '0');
        return '${dt.year}-$m';
      }

      final s = fmt(val('startDate'));
      final ee = fmt(val('endDate'));
      if (s.isEmpty && ee.isEmpty) return '';
      return ee.isEmpty ? '$s - Present' : '$s - $ee';
    }

    final lines = <pw.Widget>[];
    if (val('degree').isNotEmpty) {
      lines.add(
        pw.Text(
          val('degree'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      );
    }
    if (val('institution').isNotEmpty) lines.add(pw.Text(val('institution')));
    final r = range();
    final row = <pw.Widget>[];
    if (r.isNotEmpty) row.add(pw.Text(r));
    if (val('location').isNotEmpty) {
      if (row.isNotEmpty) row.add(pw.SizedBox(width: 12));
      row.add(pw.Text(val('location')));
    }
    if (row.isNotEmpty) lines.add(pw.Row(children: row));
    if (val('description').isNotEmpty) lines.add(pw.Text(val('description')));
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  pw.Widget _bulletsFromCsv(
    String csv, {
    PdfColor bulletColor = PdfColors.black,
  }) {
    final parts = csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [for (final s in parts) _bulletLine(s, color: bulletColor)],
    );
  }

  pw.Widget _bulletLine(String text, {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.Expanded(child: pw.Text(text)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseJsonArray(dynamic raw) {
    try {
      if (raw == null) return const [];
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
      final s = raw.toString();
      if (s.trim().isEmpty) return const [];
      final arr = jsonDecode(s) as List<dynamic>;
      return List<Map<String, dynamic>>.from(arr);
    } catch (_) {
      return const [];
    }
  }

  bool _looksLikeJsonArray(String v) {
    final t = v.trim();
    return t.startsWith('[') && t.endsWith(']');
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<void> _shareViaEmailInternal(
    File pdfFile,
    String subject,
    Map<String, dynamic> resumeData,
  ) async {
    final fileName =
        '${(resumeData['full_name'] ?? 'resume').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    print(
      'DEBUG: Attempting to share PDF via Email. Path: ${pdfFile.path}. FileName: $fileName',
    );

    try {
      final xFile = XFile(
        pdfFile.path,
        name: fileName,
        mimeType: 'application/pdf',
      );

      // Use path-based sharing for broader Android compatibility
      final result = await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: 'Please find the attached resume.',
      );

      if (result.status == ShareResultStatus.success) {
        print('DEBUG: Email share successful.');
      } else {
        print('DEBUG: Email share dismissed or failed. Raw: ${result.raw}');
        await _launchEmailFallback(subject);
      }
    } catch (e, s) {
      print('DEBUG: Error sharing via Email with attachment: $e\n$s');
      await _launchEmailFallback(subject);
    }
  }

  Future<void> _launchEmailFallback(String subject) async {
    print('DEBUG: Falling back to mailto: URL launcher for email.');
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent('Please find the attached resume.')}',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      await _showErrorDialog('Could not open email app.');
    }
  }

  Future<void> _shareViaWhatsAppInternal(
    File pdfFile,
    String subject,
    Map<String, dynamic> resumeData,
  ) async {
    final fileName =
        '${(resumeData['full_name'] ?? 'resume').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    print(
      'DEBUG: Attempting to share PDF via WhatsApp. Path: ${pdfFile.path}. FileName: $fileName',
    );

    try {
      final xFile = XFile(
        pdfFile.path,
        name: fileName,
        mimeType: 'application/pdf',
      );

      // Note: share_plus cannot force WhatsApp; it shows the share sheet.
      // Users can pick WhatsApp and the attachment will be preserved.
      final result = await Share.shareXFiles([
        xFile,
      ], text: 'Here is the resume.');

      if (result.status == ShareResultStatus.success) {
        print('DEBUG: WhatsApp share successful.');
      } else {
        print('DEBUG: WhatsApp share dismissed or failed. Raw: ${result.raw}');
        await _launchWhatsAppFallback();
      }
    } catch (e, s) {
      print('DEBUG: Error sharing via WhatsApp with attachment: $e\n$s');
      await _launchWhatsAppFallback();
    }
  }

  Future<void> _launchWhatsAppFallback() async {
    print('DEBUG: Falling back to whatsapp:// URL launcher.');
    const message = 'Here is the resume.';
    // Using the new recommended format for WhatsApp links
    final whatsappUrl = "https://wa.me/?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _showErrorDialog('Could not open WhatsApp.');
      }
    } catch (e) {
      await _showErrorDialog('Failed to open WhatsApp.');
    }
  }

  Future<void> printResume(SavedResume resume) async {
    if (await PremiumService.isPremiumWithDialog(context)) {
      if (resume.template != 'One Page') {
        final ok = await _ensureFullNameIfMissing(resume);
        if (!ok) return;
      }
      final pdfFile = await _generatePdf(resume);
      if (pdfFile != null) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) => pdfFile.readAsBytes(),
        );
      } else {
        _showErrorDialog('Failed to generate PDF for printing.');
      }
    }
  }

  Future<void> exportAndOpenPdf(SavedResume resume) async {
    if (await PremiumService.isPremiumWithDialog(context)) {
      if (resume.template != 'One Page') {
        final ok = await _ensureFullNameIfMissing(resume);
        if (!ok) return;
      }
      File? pdfFile;
      try {
        pdfFile = await _generatePdf(resume);
      } catch (e, s) {
        print('DEBUG: Exception during PDF generation for export: $e\n$s');
        await _showErrorDialog('Failed to generate PDF for export.');
        return;
      }
      if (pdfFile != null) {
        final outputDir = await _getExportBaseDir();
        if (outputDir != null) {
          final sanitizedName = _sanitize(resume.data['full_name'] ?? 'resume');
          final finalPath = p.join(
            outputDir.path,
            '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          final finalFile = await pdfFile.copy(finalPath);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${finalFile.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  OpenFile.open(finalFile.path);
                },
              ),
            ),
          );
        } else {
          await _showErrorDialog('Could not access storage directory.');
        }
      } else {
        _showErrorDialog('Failed to generate PDF for export.');
      }
    }
  }

  Future<void> exportAndOpenDocx(SavedResume resume) async {
    if (await PremiumService.isPremiumWithDialog(context)) {
      if (resume.template != 'One Page') {
        final ok = await _ensureFullNameIfMissing(resume);
        if (!ok) return;
      }

      final outputDir = await _getExportBaseDir();
      if (outputDir == null) {
        await _showErrorDialog('Could not access storage directory.');
        return;
      }

      final sanitizedName = _sanitize(resume.data['full_name'] ?? 'resume');
      final filePath = p.join(
        outputDir.path,
        '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.docx',
      );

      try {
        List<int> bytes;
        if (resume.template.toLowerCase() == 'professional') {
          // Use improved DOCX export for Professional template
          bytes = _buildProfessionalDocx(resume);
        } else {
          // Fallback to simple text export for other templates
          final content = _buildPlainTextForDoc(resume);
          bytes = buildDocxBytesFromPlainText(content);
        }

        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DOCX saved to ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      } catch (e) {
        await _showErrorDialog('Failed to export DOCX: $e');
      }
    }
  }

  List<int> _buildProfessionalDocx(SavedResume resume) {
    final zip = ar.Archive();

    // Add basic DOCX structure files
    zip.addFile(
      ar.ArchiveFile.string('[Content_Types].xml', _docxContentTypesXml),
    );
    zip.addFile(ar.ArchiveFile.string('_rels/.rels', _docxRelsXml));
    zip.addFile(ar.ArchiveFile.string('docProps/app.xml', _docxAppPropsXml));
    zip.addFile(ar.ArchiveFile.string('docProps/core.xml', _docxCorePropsXml));
    zip.addFile(ar.ArchiveFile.string('word/styles.xml', _docxStylesXml));
    zip.addFile(
      ar.ArchiveFile.string('word/_rels/document.xml.rels', _docxWordRelsXml),
    );

    // Create the main document content
    final documentXml = _buildProfessionalDocumentXml(resume);
    zip.addFile(ar.ArchiveFile.string('word/document.xml', documentXml));

    return ar.ZipEncoder().encode(zip)!;
  }

  String _buildProfessionalDocumentXml(SavedResume resume) {
    final data = Map<String, dynamic>.from(resume.data);
    final buffer = StringBuffer();

    // Extract basic info
    final name = (data['name'] ?? '').toString().trim();
    final title = (data['title'] ?? data['professionalTitle'] ?? '')
        .toString()
        .trim();
    final email = (data['email'] ?? '').toString().trim();
    final phone = (data['phone'] ?? '').toString().trim();
    final location = (data['location'] ?? '').toString().trim();
    final website = (data['website'] ?? data['portfolio'] ?? '')
        .toString()
        .trim();
    final summary = (data['executiveSummary'] ?? data['summary'] ?? '')
        .toString()
        .trim();

    // Start document
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>''');

    // Name as main header
    if (name.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
          <w:color w:val="2E3A47"/>
        </w:rPr>
        <w:t>${_escapeXml(name)}</w:t>
      </w:r>
    </w:p>''');
    }

    // Job title
    if (title.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="20"/>
          <w:color w:val="1976D2"/>
        </w:rPr>
        <w:t>${_escapeXml(title)}</w:t>
      </w:r>
    </w:p>''');
    }

    // Contact information
    final contacts = [
      if (email.isNotEmpty) email,
      if (phone.isNotEmpty) phone,
      if (location.isNotEmpty) location,
      if (website.isNotEmpty) website,
    ];

    if (contacts.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="360"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="18"/>
        </w:rPr>
        <w:t>${_escapeXml(contacts.join(' • '))}</w:t>
      </w:r>
    </w:p>''');
    }

    // Professional Summary
    if (summary.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="20"/>
          <w:color w:val="2E3A47"/>
        </w:rPr>
        <w:t>PROFESSIONAL SUMMARY</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="18"/>
        </w:rPr>
        <w:t>${_escapeXml(summary)}</w:t>
      </w:r>
    </w:p>''');
    }

    // Work Experience
    try {
      final workData = data['workExperiences'] ?? data['workExperiencesJson'];
      if (workData != null && workData.toString().isNotEmpty) {
        final List<dynamic> workList = jsonDecode(workData.toString());
        if (workList.isNotEmpty) {
          buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="20"/>
          <w:color w:val="2E3A47"/>
        </w:rPr>
        <w:t>PROFESSIONAL EXPERIENCE</w:t>
      </w:r>
    </w:p>''');

          for (final work in workList) {
            final jobTitle = (work['jobTitle'] ?? '').toString();
            final company = (work['company'] ?? '').toString();
            final location = (work['location'] ?? '').toString();
            final startDate = (work['startDate'] ?? '').toString();
            final endDate = (work['endDate'] ?? '').toString();
            final description = (work['description'] ?? '').toString();

            if (jobTitle.isNotEmpty) {
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="60"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="18"/>
          <w:color w:val="1976D2"/>
        </w:rPr>
        <w:t>${_escapeXml(jobTitle)}</w:t>
      </w:r>
    </w:p>''');
            }

            if (company.isNotEmpty) {
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="60"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="16"/>
        </w:rPr>
        <w:t>${_escapeXml(company)}${location.isNotEmpty ? ' • ' + location : ''}</w:t>
      </w:r>
    </w:p>''');
            }

            if (startDate.isNotEmpty || endDate.isNotEmpty) {
              final dateRange = _formatDocxDateRange(startDate, endDate);
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="60"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="14"/>
          <w:color w:val="666666"/>
        </w:rPr>
        <w:t>${_escapeXml(dateRange)}</w:t>
      </w:r>
    </w:p>''');
            }

            if (description.isNotEmpty) {
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="16"/>
        </w:rPr>
        <w:t>${_escapeXml(description)}</w:t>
      </w:r>
    </w:p>''');
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error processing work experience for DOCX: $e');
    }

    // Education
    try {
      final eduData = data['educations'] ?? data['educationsJson'];
      if (eduData != null && eduData.toString().isNotEmpty) {
        final List<dynamic> eduList = jsonDecode(eduData.toString());
        if (eduList.isNotEmpty) {
          buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="20"/>
          <w:color w:val="2E3A47"/>
        </w:rPr>
        <w:t>EDUCATION</w:t>
      </w:r>
    </w:p>''');

          for (final edu in eduList) {
            final degree = (edu['degree'] ?? '').toString();
            final institution =
                (edu['institution'] ?? edu['university'] ?? edu['school'] ?? '')
                    .toString();
            final location = (edu['location'] ?? '').toString();
            final startDate = (edu['startDate'] ?? '').toString();
            final endDate = (edu['endDate'] ?? '').toString();

            if (degree.isNotEmpty) {
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="60"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="16"/>
          <w:color w:val="1976D2"/>
        </w:rPr>
        <w:t>${_escapeXml(degree)}</w:t>
      </w:r>
    </w:p>''');
            }

            if (institution.isNotEmpty) {
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="60"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="16"/>
        </w:rPr>
        <w:t>${_escapeXml(institution)}</w:t>
      </w:r>
    </w:p>''');
            }

            if (startDate.isNotEmpty || endDate.isNotEmpty) {
              final dateRange = _formatDocxDateRange(startDate, endDate);
              buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="14"/>
          <w:color w:val="666666"/>
        </w:rPr>
        <w:t>${_escapeXml(dateRange)}</w:t>
      </w:r>
    </w:p>''');
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error processing education for DOCX: $e');
    }

    // Skills
    final skillsText = (data['keySkills'] ?? data['skills'] ?? '').toString();
    if (skillsText.isNotEmpty) {
      final skills = skillsText
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (skills.isNotEmpty) {
        buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="20"/>
          <w:color w:val="2E3A47"/>
        </w:rPr>
        <w:t>CORE SKILLS</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="16"/>
        </w:rPr>
        <w:t>${_escapeXml(skills.join(' • '))}</w:t>
      </w:r>
    </w:p>''');
      }
    }

    // End document
    buffer.write('''
  </w:body>
</w:document>''');

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _formatDocxDateRange(String startDate, String endDate) {
    if (startDate.isEmpty && endDate.isEmpty) return '';
    if (startDate.isEmpty) return endDate;
    if (endDate.isEmpty || endDate.toLowerCase() == 'present') {
      return '$startDate – Present';
    }
    return '$startDate – $endDate';
  }

  // DOCX XML templates
  String get _docxContentTypesXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>''';

  String get _docxRelsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>''';

  String get _docxAppPropsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Resume Builder App</Application>
  <DocSecurity>0</DocSecurity>
  <Lines>1</Lines>
  <Paragraphs>1</Paragraphs>
  <ScaleCrop>false</ScaleCrop>
  <SharedDoc>false</SharedDoc>
  <LinksUpToDate>false</LinksUpToDate>
</Properties>''';

  String get _docxCorePropsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Professional Resume</dc:title>
  <dc:creator>Resume Builder App</dc:creator>
  <dcterms:created xsi:type="dcterms:W3CDTF">${DateTime.now().toIso8601String()}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${DateTime.now().toIso8601String()}</dcterms:modified>
</cp:coreProperties>''';

  String get _docxStylesXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
        <w:sz w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';

  String get _docxWordRelsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  String _buildPlainTextForDoc(SavedResume resume) {
    final data = Map<String, dynamic>.from(resume.data);
    final buffer = StringBuffer();
    final fullName = (data['full_name'] ?? data['name'] ?? resume.title)
        .toString()
        .trim();
    final email = (data['email'] ?? '').toString().trim();
    final phone = (data['phone'] ?? '').toString().trim();
    final portfolio = (data['portfolio'] ?? '').toString().trim();
    final linkedin = (data['linkedin'] ?? data['linkedIn'] ?? '').toString();

    // Header
    buffer.writeln(fullName);
    if (email.isNotEmpty ||
        phone.isNotEmpty ||
        portfolio.isNotEmpty ||
        linkedin.isNotEmpty) {
      final contacts = [
        if (phone.isNotEmpty) phone,
        if (email.isNotEmpty) email,
        if (portfolio.isNotEmpty) portfolio,
        if (linkedin.isNotEmpty) linkedin,
      ].join(' • ');
      buffer.writeln(contacts);
    }

    void addSection(String title, List<String> lines) {
      if (lines.isEmpty) return;
      buffer.writeln('');
      buffer.writeln(title.toUpperCase());
      for (final l in lines) {
        buffer.writeln(l);
      }
    }

    // Summary (use template-specific key if available)
    final summary =
        (data['creativeSummary'] ??
                data['executiveSummary'] ??
                data['summary'] ??
                '')
            .toString()
            .trim();
    if (summary.isNotEmpty) {
      addSection('Summary', [summary]);
    }

    // Skills
    final skillsCsv =
        (data['skills'] ?? data['skillsCsv'] ?? data['coreSkills'] ?? '')
            .toString()
            .trim();
    if (skillsCsv.isNotEmpty) {
      addSection('Skills', [skillsCsv]);
    }

    // Tools
    final tools = (data['tools'] ?? '').toString().trim();
    if (tools.isNotEmpty) {
      addSection('Tools & Software', [tools]);
    }

    // Work Experience
    List<Map<String, dynamic>> work = [];
    if (data['workExperiences'] != null) {
      work = _parseJsonArray(data['workExperiences']);
    } else if (data['workExperiencesJson'] != null) {
      work = _parseJsonArray(data['workExperiencesJson']);
    }
    if (work.isNotEmpty) {
      final lines = <String>[];
      for (final w in work) {
        String val(String k) => (w[k] ?? '').toString();
        String fmtDate(String iso) {
          if (iso.isEmpty) return '';
          final dt = DateTime.tryParse(iso);
          if (dt == null) return '';
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        }

        final start = fmtDate(val('startDate'));
        final end = fmtDate(val('endDate'));
        final range = start.isEmpty && end.isEmpty
            ? ''
            : end.isEmpty
            ? '$start - Present'
            : '$start - $end';
        final title = val('jobTitle');
        final company = val('company');
        final line = [
          if (title.isNotEmpty) title,
          if (company.isNotEmpty) 'at $company',
          if (range.isNotEmpty) '($range)',
        ].join(' ');
        if (line.isNotEmpty) lines.add(line);
        final desc = val('description');
        if (desc.isNotEmpty) {
          for (final l in desc.split(RegExp(r'\r?\n+'))) {
            final s = l.trim();
            if (s.isEmpty) continue;
            lines.add('- $s');
          }
        }
      }
      addSection('Professional Experience', lines);
    }

    // Education
    List<Map<String, dynamic>> edus = [];
    if (data['educations'] != null) {
      edus = _parseJsonArray(data['educations']);
    } else if (data['educationsJson'] != null) {
      edus = _parseJsonArray(data['educationsJson']);
    }
    if (edus.isNotEmpty) {
      final lines = <String>[];
      for (final e in edus) {
        String val(String k) => (e[k] ?? '').toString();
        String fmtDate(String iso) {
          if (iso.isEmpty) return '';
          final dt = DateTime.tryParse(iso);
          if (dt == null) return '';
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        }

        final start = fmtDate(val('startDate'));
        final end = fmtDate(val('endDate'));
        final range = start.isEmpty && end.isEmpty
            ? ''
            : end.isEmpty
            ? '$start - Present'
            : '$start - $end';
        final degree = val('degree');
        final inst = val('institution');
        final uni = val('university');
        final school = inst.isNotEmpty ? inst : uni;
        final line = [
          if (degree.isNotEmpty) degree,
          if (school.isNotEmpty) 'at $school',
          if (range.isNotEmpty) '($range)',
        ].join(' ');
        if (line.isNotEmpty) lines.add(line);
        final desc = val('description');
        if (desc.isNotEmpty) lines.add(desc);
      }
      addSection('Education', lines);
    }

    // Other simple sections
    for (final key in ['projects', 'languages', 'hobbies', 'references']) {
      final v = (data[key] ?? '').toString().trim();
      if (v.isNotEmpty) addSection(_formatKey(key), [v]);
    }

    return buffer.toString().trim();
  }

  Future<Directory?> _getExportBaseDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir;
      // Fallback so export still works even if external storage is unavailable
      return await getTemporaryDirectory();
    } else {
      return getApplicationDocumentsDirectory();
    }
  }

  String _sanitize(String filename) {
    return filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> _showErrorDialog(String message) async {
    if (context.mounted) {
      // Defer to next microtask to avoid colliding with PopupMenu route teardown
      await Future<void>.delayed(const Duration(milliseconds: 10));
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  // Prompt for user's name when missing so it can appear under "Curriculum Vitae"
  Future<bool> _ensureFullNameIfMissing(SavedResume resume) async {
    final existing = (resume.data['full_name']?.toString() ?? '').trim();
    if (existing.isNotEmpty) return true;

    // Auto-fill from 'name' if available to avoid prompting
    final fallbackName = (resume.data['name']?.toString() ?? '').trim();
    if (fallbackName.isNotEmpty) {
      resume.data['full_name'] = fallbackName;
      return true;
    }

    final initial = (resume.title.toString()).trim();
    final entered = await _promptForName(initial: initial);
    if (entered == null || entered.trim().isEmpty) {
      // user cancelled or left empty
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Name is required to continue. Tap Edit to add your name.',
            ),
          ),
        );
      }
      return false;
    }
    resume.data['full_name'] = entered.trim();
    return true;
  }

  Future<String?> _promptForName({String initial = ''}) async {
    if (!context.mounted) return null;
    final controller = TextEditingController(text: initial);
    // Defer to allow any menus to close before showing the dialog, and use root navigator
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter your name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full name',
            hintText: 'e.g., John Doe',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
