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

import '../models/saved_resume.dart';
import 'one_page_pdf_exporter.dart';
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
    final accent = PdfColors.indigo;

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
                                style: pw.TextStyle(color: PdfColors.grey800),
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
                                style: pw.TextStyle(color: PdfColors.grey800),
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
                                style: pw.TextStyle(color: PdfColors.indigo),
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
                                style: pw.TextStyle(color: PdfColors.indigo),
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
            }).toList(),
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
    final safe = (String s) => _sanitizeForPdfText(s);
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
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
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
        final content = _buildPlainTextForDoc(resume);
        final bytes = buildDocxBytesFromPlainText(content);
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
