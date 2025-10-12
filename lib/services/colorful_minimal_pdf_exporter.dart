import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/saved_resume.dart';
import '../screens/minimal_template_selection_screen.dart';

class ColorfulMinimalPdfExporter {
  static Future<List<int>> build(SavedResume resume) async {
    // Extract theme information from resume data
    final themeData = resume.data['colorTheme'] as Map<String, dynamic>?;

    // Default theme if none specified
    final theme = themeData != null
        ? MinimalTemplateTheme(
            id: themeData['id'] ?? 'default',
            name: themeData['name'] ?? 'Default',
            description: '',
            primaryColor: themeData['primaryColor'] ?? '#2196F3',
            secondaryColor: themeData['secondaryColor'] ?? '#757575',
            accentColor: themeData['accentColor'] ?? '#FF5722',
            backgroundColor: themeData['backgroundColor'] ?? '#FFFFFF',
            textColor: themeData['textColor'] ?? '#333333',
            icon: Icons.description,
          )
        : const MinimalTemplateTheme(
            id: 'default',
            name: 'Default',
            description: '',
            primaryColor: '#2196F3',
            secondaryColor: '#757575',
            accentColor: '#FF5722',
            backgroundColor: '#FFFFFF',
            textColor: '#333333',
            icon: Icons.description,
          );

    final pdf = pw.Document();

    // Convert hex colors to PdfColor
    final primaryColor = _hexToPdfColor(theme.primaryColor);
    final secondaryColor = _hexToPdfColor(theme.secondaryColor);
    final accentColor = _hexToPdfColor(theme.accentColor);
    final textColor = _hexToPdfColor(theme.textColor);
    final backgroundColor = _hexToPdfColor(theme.backgroundColor);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Green Header Section
              _buildProfessionalHeader(resume, primaryColor, backgroundColor),

              // White Content Section
              pw.Expanded(
                child: pw.Container(
                  color: backgroundColor,
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Contact Information
                      _buildContactInfo(resume, textColor, accentColor),
                      pw.SizedBox(height: 24),

                      // Professional Summary
                      _buildSummary(resume, primaryColor, textColor),
                      pw.SizedBox(height: 24),

                      // Skills
                      _buildSkills(
                        resume,
                        primaryColor,
                        accentColor,
                        textColor,
                      ),
                      pw.SizedBox(height: 24),

                      // Work Experience
                      _buildWorkExperience(
                        resume,
                        primaryColor,
                        secondaryColor,
                        accentColor,
                        textColor,
                      ),
                      pw.SizedBox(height: 24),

                      // Education
                      _buildEducation(
                        resume,
                        primaryColor,
                        secondaryColor,
                        accentColor,
                        textColor,
                      ),
                      pw.SizedBox(height: 24),

                      // Additional Sections
                      _buildAdditionalSections(resume, primaryColor, textColor),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildProfessionalHeader(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor backgroundColor,
  ) {
    final name = resume.data['name'] ?? 'Your Name';
    final jobTitle = resume.data['jobTitle'] ?? resume.data['title'] ?? '';
    final email = resume.data['email'] ?? '';
    final phone = resume.data['phone'] ?? '';

    return pw.Container(
      height: 140,
      color: primaryColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: pw.Row(
        children: [
          // Profile Photo Placeholder (circular)
          pw.Container(
            width: 90,
            height: 90,
            decoration: pw.BoxDecoration(
              color: backgroundColor,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: backgroundColor, width: 3),
            ),
            child: pw.Center(
              child: pw.Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'Y',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 24),

          // Name and Title Section
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: backgroundColor,
                  ),
                ),
                if (jobTitle.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    jobTitle,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.normal,
                      color: backgroundColor,
                    ),
                  ),
                ],
                if (email.isNotEmpty || phone.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      if (email.isNotEmpty) ...[
                        pw.Text(
                          email,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: backgroundColor,
                          ),
                        ),
                      ],
                      if (email.isNotEmpty && phone.isNotEmpty) ...[
                        pw.SizedBox(width: 16),
                        pw.Container(
                          width: 1,
                          height: 12,
                          color: backgroundColor,
                        ),
                        pw.SizedBox(width: 16),
                      ],
                      if (phone.isNotEmpty) ...[
                        pw.Text(
                          phone,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: backgroundColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContactInfo(
    SavedResume resume,
    PdfColor textColor,
    PdfColor accentColor,
  ) {
    final linkedin = resume.data['linkedIn'] ?? resume.data['linkedin'] ?? '';
    final website = resume.data['website'] ?? '';
    final address = resume.data['address'] ?? '';

    final contactItems = <String>[];
    if (linkedin.isNotEmpty) contactItems.add('LinkedIn: $linkedin');
    if (website.isNotEmpty) contactItems.add('Website: $website');
    if (address.isNotEmpty) contactItems.add('Address: $address');

    if (contactItems.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Contact Information', accentColor),
        pw.SizedBox(height: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: contactItems
              .map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(fontSize: 12, color: textColor),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor textColor,
  ) {
    final summary = resume.data['summary'] ?? resume.data['objective'] ?? '';

    if (summary.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Professional Summary', primaryColor),
        pw.SizedBox(height: 12),
        pw.Text(
          summary,
          style: pw.TextStyle(fontSize: 14, height: 1.6, color: textColor),
        ),
      ],
    );
  }

  static pw.Widget _buildSkills(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    final skills = resume.data['skills'] ?? '';

    if (skills.isEmpty) return pw.SizedBox.shrink();

    final skillsList = skills
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty as bool)
        .toList();

    if (skillsList.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills', primaryColor),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skillsList
              .map(
                (skill) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(16),
                    border: pw.Border.all(color: accentColor),
                  ),
                  child: pw.Text(
                    skill,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildWorkExperience(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    final workExperiencesJson = resume.data['workExperiences'] ?? '';

    if (workExperiencesJson.isEmpty) return pw.SizedBox.shrink();

    List<dynamic> experiences;
    try {
      experiences = jsonDecode(workExperiencesJson);
    } catch (e) {
      return pw.SizedBox.shrink();
    }

    if (experiences.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Work Experience', primaryColor),
        pw.SizedBox(height: 16),
        ...experiences.map(
          (exp) => _buildExperienceItem(
            exp,
            primaryColor,
            secondaryColor,
            accentColor,
            textColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildExperienceItem(
    dynamic experience,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    final jobTitle = experience['jobTitle'] ?? '';
    final company = experience['company'] ?? '';
    final startDate = experience['startDate'] ?? '';
    final endDate = experience['endDate'] ?? '';
    final description = experience['description'] ?? '';
    final achievements = experience['achievements'] ?? '';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 6, right: 12),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  jobTitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (company.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    company,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                      color: secondaryColor,
                    ),
                  ),
                ],
                if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${startDate.isNotEmpty ? startDate : ''} - ${endDate.isNotEmpty ? endDate : 'Present'}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    description,
                    style: pw.TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                ],
                if (achievements.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    achievements,
                    style: pw.TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEducation(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    final educationsJson = resume.data['educations'] ?? '';

    if (educationsJson.isEmpty) return pw.SizedBox.shrink();

    List<dynamic> educations;
    try {
      educations = jsonDecode(educationsJson);
    } catch (e) {
      return pw.SizedBox.shrink();
    }

    if (educations.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education', primaryColor),
        pw.SizedBox(height: 16),
        ...educations.map(
          (edu) => _buildEducationItem(
            edu,
            primaryColor,
            secondaryColor,
            accentColor,
            textColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEducationItem(
    dynamic education,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    final degree = education['degree'] ?? '';
    final institution =
        education['institution'] ??
        education['university'] ??
        education['school'] ??
        '';
    final startDate = education['startDate'] ?? '';
    final endDate = education['endDate'] ?? '';
    final description = education['description'] ?? '';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 6, right: 12),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  degree,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (institution.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    institution,
                    style: pw.TextStyle(fontSize: 14, color: secondaryColor),
                  ),
                ],
                if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${startDate.isNotEmpty ? startDate : ''} - ${endDate.isNotEmpty ? endDate : 'Present'}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    description,
                    style: pw.TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAdditionalSections(
    SavedResume resume,
    PdfColor primaryColor,
    PdfColor textColor,
  ) {
    final languages = resume.data['languages'] ?? '';
    final hobbies = resume.data['hobbies'] ?? '';
    final certifications = resume.data['certifications'] ?? '';

    if (languages.isEmpty && hobbies.isEmpty && certifications.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (languages.isNotEmpty) ...[
          _buildSimpleSection('Languages', languages, primaryColor, textColor),
          pw.SizedBox(height: 16),
        ],
        if (certifications.isNotEmpty) ...[
          _buildSimpleSection(
            'Certifications',
            certifications,
            primaryColor,
            textColor,
          ),
          pw.SizedBox(height: 16),
        ],
        if (hobbies.isNotEmpty) ...[
          _buildSimpleSection(
            'Interests & Hobbies',
            hobbies,
            primaryColor,
            textColor,
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSimpleSection(
    String title,
    String content,
    PdfColor primaryColor,
    PdfColor textColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, primaryColor),
        pw.SizedBox(height: 8),
        pw.Text(
          content,
          style: pw.TextStyle(fontSize: 13, height: 1.5, color: textColor),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static PdfColor _hexToPdfColor(String hex) {
    // Remove # if present
    hex = hex.replaceAll('#', '');

    // Parse RGB values
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);

    return PdfColor.fromInt((r << 16) | (g << 8) | b);
  }
}
