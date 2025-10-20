import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/saved_resume.dart';
import '../models/branding.dart';

class ProfessionalPdfExporter {
  static Future<Uint8List> build(SavedResume resume) async {
    // Load fonts
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

    // Helper functions
    String val(String k) => (data[k] ?? '').toString().trim();
    String or(List<String> keys) {
      for (final k in keys) {
        final v = val(k);
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    // Extract basic info - updated to match form field names
    final fullName = or(['full_name', 'name']) == ''
        ? resume.title
        : or(['full_name', 'name']);
    final title = or(['title', 'professionalTitle']);
    final email = val('email');
    final phone = val('phone');
    final location = val('location');
    final portfolio = or(['portfolio', 'website']);
    final linkedin = or(['linkedIn', 'linkedin']);
    final summary = or([
      'executiveSummary',
      'summary',
    ]); // Updated to match form

    // Extract additional fields from form
    final projects = val('projects');
    final languages = val('languages');
    final hobbies = val('hobbies');
    final references = val('references');
    final profilePhotoBase64 = val('profilePhotoBase64');

    // Extract layout
    final layout = val('layout') == '' ? 'Single Column' : val('layout');

    // Extract branding theme
    PdfColor primaryColor = PdfColors.grey800;
    PdfColor accentColor = PdfColors.indigo;

    try {
      final brandingJson = data['branding'];
      if (brandingJson != null && brandingJson.toString().isNotEmpty) {
        final theme = BrandingTheme.fromJson(
          jsonDecode(brandingJson.toString()) as Map<String, dynamic>,
        );
        primaryColor = _hexToPdfColor(theme.primaryColor);
        accentColor = _hexToPdfColor(theme.accentColor);
      }
    } catch (_) {}

    // Parse JSON arrays
    List<Map<String, dynamic>> parseJsonArray(String key) {
      final raw = data[key] ?? data['${key}Json'];
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

    final workExperiences = parseJsonArray('workExperiences');
    final educations = parseJsonArray('educations');

    // Parse skills and certifications - updated to match form field names
    final skillsCsv = or([
      'keySkills',
      'skills',
      'coreSkills',
    ]); // Updated to match form
    final skills = skillsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final certificationsCsv = val('certifications');
    final certifications = certificationsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Date formatting
    String fmtRange(String startIso, String endIso) {
      String fmt(String iso) {
        if (iso.isEmpty) return '';
        final dt = DateTime.tryParse(iso);
        if (dt == null) return '';
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$m/$d/${dt.year}';
      }

      final start = fmt(startIso);
      final end = fmt(endIso);
      if (start.isEmpty && end.isEmpty) return '';
      if (end.isEmpty) return '$start - Present';
      return '$start - $end';
    }

    // Contact rows builder
    List<pw.Widget> buildContactRows() {
      final contacts = <String>[];
      if (email.isNotEmpty) contacts.add('• $email');
      if (phone.isNotEmpty) contacts.add('• $phone');
      if (location.isNotEmpty) contacts.add('• $location');
      if (linkedin.isNotEmpty) contacts.add('• $linkedin');
      if (portfolio.isNotEmpty) contacts.add('• $portfolio');

      return contacts
          .map(
            (contact) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(contact, style: const pw.TextStyle(fontSize: 11)),
            ),
          )
          .toList();
    }

    // Section header builder
    pw.Widget sectionHeader(String text) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
        decoration: pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    // Contact info builder
    pw.Widget buildContactInfo() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Profile Photo
          if (profilePhotoBase64.isNotEmpty) ...[
            pw.Center(
              child: pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: primaryColor, width: 2),
                ),
                child: pw.ClipOval(
                  child: pw.Image(
                    pw.MemoryImage(base64Decode(profilePhotoBase64)),
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          // Name
          pw.Text(
            fullName,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          // Professional title
          if (title.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                color: accentColor,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          // Contact details
          ...buildContactRows(),
        ],
      );
    }

    // Main content builder
    pw.Widget buildMainContent() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Professional Summary
          if (summary.isNotEmpty) ...[
            sectionHeader('Professional Summary'),
            pw.Text(
              summary,
              style: const pw.TextStyle(fontSize: 11, height: 1.4),
            ),
          ],

          // Work Experience
          if (workExperiences.isNotEmpty) ...[
            sectionHeader('Professional Experience'),
            ...workExperiences.map(
              (exp) => buildExperienceItem(exp, fmtRange, accentColor),
            ),
          ],

          // Education
          if (educations.isNotEmpty) ...[
            sectionHeader('Education'),
            ...educations.map(
              (edu) => buildEducationItem(edu, fmtRange, accentColor),
            ),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            sectionHeader('Core Skills'),
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills
                  .map(
                    (skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accentColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        skill,
                        style: pw.TextStyle(fontSize: 9, color: accentColor),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Certifications
          if (certifications.isNotEmpty) ...[
            sectionHeader('Certifications'),
            ...certifications.map(
              (cert) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• ',
                      style: pw.TextStyle(color: accentColor, fontSize: 11),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        cert,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Projects
          if (projects.isNotEmpty) ...[
            sectionHeader('Projects'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                projects,
                style: const pw.TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
          ],

          // Languages
          if (languages.isNotEmpty) ...[
            sectionHeader('Languages'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                languages,
                style: const pw.TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
          ],

          // Hobbies
          if (hobbies.isNotEmpty) ...[
            sectionHeader('Hobbies'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                hobbies,
                style: const pw.TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
          ],

          // References
          if (references.isNotEmpty) ...[
            sectionHeader('References'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                references,
                style: const pw.TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ],
      );
    }

    // Build the page based on layout
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          switch (layout) {
            case 'Two Columns':
              return [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 1, child: buildContactInfo()),
                    pw.SizedBox(width: 16),
                    pw.Expanded(flex: 2, child: buildMainContent()),
                  ],
                ),
              ];
            case 'Sidebar':
              return [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 140,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: primaryColor.shade(0.1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: buildContactInfo(),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(child: buildMainContent()),
                  ],
                ),
              ];
            default: // Single Column and others
              return [
                buildContactInfo(),
                pw.SizedBox(height: 12),
                buildMainContent(),
              ];
          }
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget buildExperienceItem(
    Map<String, dynamic> exp,
    String Function(String, String) fmtRange,
    PdfColor accentColor,
  ) {
    final jobTitle = (exp['jobTitle'] ?? '').toString();
    final company = (exp['company'] ?? '').toString();
    final location = (exp['location'] ?? '').toString();
    final startDate = (exp['startDate'] ?? '').toString();
    final endDate = (exp['endDate'] ?? '').toString();
    final description = (exp['description'] ?? '').toString();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            jobTitle,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (company.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              company + (location.isNotEmpty ? ' • $location' : ''),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              fmtRange(startDate, endDate),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              description,
              style: const pw.TextStyle(fontSize: 11, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget buildEducationItem(
    Map<String, dynamic> edu,
    String Function(String, String) fmtRange,
    PdfColor accentColor,
  ) {
    final degree = (edu['degree'] ?? '').toString();
    final institution =
        (edu['institution'] ?? edu['university'] ?? edu['school'] ?? '')
            .toString();
    final startDate = (edu['startDate'] ?? '').toString();
    final endDate = (edu['endDate'] ?? '').toString();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            degree,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (institution.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(institution, style: const pw.TextStyle(fontSize: 11)),
          ],
          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              fmtRange(startDate, endDate),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static PdfColor _hexToPdfColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      if (hexCode.length == 6) {
        final r = int.parse(hexCode.substring(0, 2), radix: 16) / 255.0;
        final g = int.parse(hexCode.substring(2, 4), radix: 16) / 255.0;
        final b = int.parse(hexCode.substring(4, 6), radix: 16) / 255.0;
        return PdfColor(r, g, b);
      }
    } catch (_) {}
    return PdfColors.grey800;
  }
}
