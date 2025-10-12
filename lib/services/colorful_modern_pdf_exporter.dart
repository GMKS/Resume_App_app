import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/saved_resume.dart';
import '../screens/modern_template_selection_screen.dart';

class ColorfulModernPdfExporter {
  static Future<String> exportToPdf(
    SavedResume resume,
    ModernTemplateTheme theme,
  ) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex(theme.primaryColor.substring(1));
    const lightColor = PdfColor.fromInt(0xFFF0F0F0); // Light background color

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with theme color
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      resume.data['name'] ?? 'Your Name',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      resume.data['jobTitle'] ?? 'Your Job Title',
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Contact Information Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _buildContactInfo(resume)),
                  pw.SizedBox(width: 24),
                  pw.Expanded(child: _buildAdditionalContact(resume)),
                ],
              ),
              pw.SizedBox(height: 24),

              // Professional Summary
              if (resume.data['summary']?.toString().isNotEmpty == true)
                _buildSection(
                  'Professional Summary',
                  pw.Text(
                    resume.data['summary'],
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  primaryColor,
                  lightColor,
                ),

              // Work Experience
              if (_getWorkExperience(resume).isNotEmpty)
                _buildSection(
                  'Work Experience',
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: _getWorkExperience(resume)
                        .map((exp) => _buildWorkExperience(exp, primaryColor))
                        .toList(),
                  ),
                  primaryColor,
                  lightColor,
                ),

              // Education
              if (_getEducation(resume).isNotEmpty)
                _buildSection(
                  'Education',
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: _getEducation(
                      resume,
                    ).map((edu) => _buildEducation(edu, primaryColor)).toList(),
                  ),
                  primaryColor,
                  lightColor,
                ),

              // Skills
              if (_getSkills(resume).isNotEmpty)
                _buildSection(
                  'Skills',
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getSkills(resume)
                        .map((skill) => _buildSkillChip(skill, primaryColor))
                        .toList(),
                  ),
                  primaryColor,
                  lightColor,
                ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'modern_resume_${theme.name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _buildSection(
    String title,
    pw.Widget content,
    PdfColor primaryColor,
    PdfColor lightColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: lightColor,
            border: pw.Border(
              left: pw.BorderSide(color: primaryColor, width: 4),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: content),
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildContactInfo(SavedResume resume) {
    final contactItems = <pw.Widget>[];

    if (resume.data['email']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('Email:', resume.data['email']));
    }
    if (resume.data['phone']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('Phone:', resume.data['phone']));
    }
    if (resume.data['location']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('Location:', resume.data['location']));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  static pw.Widget _buildAdditionalContact(SavedResume resume) {
    final contactItems = <pw.Widget>[];

    if (resume.data['linkedin']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('LinkedIn:', resume.data['linkedin']));
    }
    if (resume.data['github']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('GitHub:', resume.data['github']));
    }
    if (resume.data['website']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem('Website:', resume.data['website']));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  static pw.Widget _buildContactItem(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkExperience(
    Map<String, dynamic> exp,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp['role'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatDateRange(exp['start'], exp['end']),
                style: const pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            exp['company'] ?? '',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
              color: primaryColor,
            ),
          ),
          if (exp['description']?.toString().isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              exp['description'],
              style: const pw.TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildEducation(
    Map<String, dynamic> edu,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu['degree'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatDateRange(edu['start'], edu['end']),
                style: const pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            edu['school'] ?? edu['college'] ?? '',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSkillChip(String skill, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0F0F0),
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: primaryColor),
      ),
      child: pw.Text(
        skill.trim(),
        style: pw.TextStyle(
          fontSize: 12,
          color: primaryColor,
          fontWeight: pw.FontWeight.normal,
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _getWorkExperience(SavedResume resume) {
    final List<Map<String, dynamic>> experience = [];

    if (resume.data['workTimeline'] is List) {
      for (final item in resume.data['workTimeline']) {
        if (item is Map<String, dynamic>) {
          experience.add(item);
        }
      }
    }

    return experience;
  }

  static List<Map<String, dynamic>> _getEducation(SavedResume resume) {
    final List<Map<String, dynamic>> education = [];

    if (resume.data['eduTimeline'] is List) {
      for (final item in resume.data['eduTimeline']) {
        if (item is Map<String, dynamic>) {
          education.add(item);
        }
      }
    }

    return education;
  }

  static List<String> _getSkills(SavedResume resume) {
    final List<String> skills = [];

    if (resume.data['skills'] is String &&
        resume.data['skills'].toString().isNotEmpty) {
      skills.addAll(
        resume.data['skills']
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    } else if (resume.data['skillsCsv'] is String &&
        resume.data['skillsCsv'].toString().isNotEmpty) {
      skills.addAll(
        resume.data['skillsCsv']
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    } else if (resume.data['skillsList'] is List) {
      for (final skill in resume.data['skillsList']) {
        if (skill.toString().isNotEmpty) {
          skills.add(skill.toString().trim());
        }
      }
    }

    return skills;
  }

  static String _formatDateRange(dynamic start, dynamic end) {
    if (start == null) return '';

    String startStr = start.toString();
    String endStr = end?.toString() ?? 'Present';

    try {
      if (startStr.contains('-') && startStr.length >= 7) {
        final startParts = startStr.split('-');
        if (startParts.length >= 2) {
          startStr = '${startParts[1]}/${startParts[0]}';
        }
      }

      if (endStr != 'Present' && endStr.contains('-') && endStr.length >= 7) {
        final endParts = endStr.split('-');
        if (endParts.length >= 2) {
          endStr = '${endParts[1]}/${endParts[0]}';
        }
      }
    } catch (e) {
      // Use original strings if parsing fails
    }

    return '$startStr - $endStr';
  }
}
