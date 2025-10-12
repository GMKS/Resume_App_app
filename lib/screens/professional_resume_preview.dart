import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/saved_resume.dart';
import '../models/branding.dart';

class ProfessionalResumePreview extends StatelessWidget {
  final SavedResume resume;
  const ProfessionalResumePreview({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final d = resume.data;

    // Extract basic info - updated to match form field names
    String name = (d['name'] ?? '').toString().trim();
    String title = (d['title'] ?? d['professionalTitle'] ?? '')
        .toString()
        .trim();
    String email = (d['email'] ?? '').toString().trim();
    String phone = (d['phone'] ?? '').toString().trim();
    String location = (d['location'] ?? '').toString().trim();
    String linkedin = (d['linkedIn'] ?? d['linkedin'] ?? '').toString().trim();
    String portfolio = (d['portfolio'] ?? d['website'] ?? '').toString().trim();
    String summary = (d['executiveSummary'] ?? d['summary'] ?? '')
        .toString()
        .trim();

    // Extract skills - updated to match keySkills field
    final skillsCsv = (d['keySkills'] ?? d['skills'] ?? d['coreSkills'] ?? '')
        .toString();
    final skills = skillsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Extract additional fields from form
    String projects = (d['projects'] ?? '').toString().trim();
    String languages = (d['languages'] ?? '').toString().trim();
    String hobbies = (d['hobbies'] ?? '').toString().trim();
    String references = (d['references'] ?? '').toString().trim();
    String profilePhotoBase64 = (d['profilePhotoBase64'] ?? '')
        .toString()
        .trim();

    // Extract certifications
    final certificationsCsv = (d['certifications'] ?? '').toString();
    final certs = certificationsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Extract work experience
    List<Map<String, dynamic>> work = [];
    if ((d['workExperiences'] ?? d['workExperiencesJson'] ?? '')
        .toString()
        .isNotEmpty) {
      try {
        final workData = d['workExperiences'] ?? d['workExperiencesJson'];
        final list = jsonDecode(workData.toString()) as List<dynamic>;
        work = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    // Extract education
    List<Map<String, dynamic>> edu = [];
    if ((d['educations'] ?? d['educationsJson'] ?? '').toString().isNotEmpty) {
      try {
        final eduData = d['educations'] ?? d['educationsJson'];
        final list = jsonDecode(eduData.toString()) as List<dynamic>;
        edu = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    // Extract branding theme
    Color primaryColor = const Color(0xFF2E3A47);
    Color accentColor = const Color(0xFF1976D2);
    String fontFamily = 'Roboto'; // Default font

    try {
      // Check for branding theme in customizations or legacy branding field
      Map<String, dynamic>? themeData;

      if (d['brandingTheme'] != null) {
        themeData = d['brandingTheme'] as Map<String, dynamic>;
      } else if (d['branding'] != null && d['branding'].toString().isNotEmpty) {
        themeData =
            jsonDecode(d['branding'].toString()) as Map<String, dynamic>;
      }

      if (themeData != null) {
        final theme = BrandingTheme.fromJson(themeData);
        primaryColor = _fromHex(theme.primaryColor);
        accentColor = _fromHex(theme.accentColor);
        fontFamily = theme.fontFamily.isNotEmpty ? theme.fontFamily : 'Roboto';
      }

      // Apply additional customizations if they exist
      final customizations = d['customizations'] as Map<String, dynamic>?;
      if (customizations != null) {
        if (customizations['fontFamily'] != null &&
            customizations['fontFamily'].toString().isNotEmpty) {
          fontFamily = customizations['fontFamily'].toString();
        }
      }
    } catch (_) {}

    // Extract layout type
    String layout = (d['layout'] ?? 'Single Column').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('${resume.title} Preview'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildLayoutContent(
          layout: layout,
          name: name,
          title: title,
          email: email,
          phone: phone,
          location: location,
          linkedin: linkedin,
          portfolio: portfolio,
          summary: summary,
          skills: skills,
          certifications: certs,
          workExperience: work,
          education: edu,
          projects: projects,
          languages: languages,
          hobbies: hobbies,
          references: references,
          profilePhotoBase64: profilePhotoBase64,
          primaryColor: primaryColor,
          accentColor: accentColor,
          fontFamily: fontFamily,
          resumeTitle: resume.title,
        ),
      ),
    );
  }

  Widget _buildLayoutContent({
    required String layout,
    required String name,
    required String title,
    required String email,
    required String phone,
    required String location,
    required String linkedin,
    required String portfolio,
    required String summary,
    required List<String> skills,
    required List<String> certifications,
    required List<Map<String, dynamic>> workExperience,
    required List<Map<String, dynamic>> education,
    required String projects,
    required String languages,
    required String hobbies,
    required String references,
    required String profilePhotoBase64,
    required Color primaryColor,
    required Color accentColor,
    required String fontFamily,
    required String resumeTitle,
  }) {
    // Helper method to create text styles with the selected font
    TextStyle textStyle({
      num? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize?.toDouble(),
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }

    Widget sectionHeader(String text) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text.toUpperCase(),
          style: textStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    Widget contactInfo() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo
          if (profilePhotoBase64.isNotEmpty) ...[
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.memory(
                    base64Decode(profilePhotoBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, size: 50, color: primaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Name and title
          Text(
            name.isEmpty ? resumeTitle : name,
            style: textStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              title,
              style: textStyle(
                fontSize: 16,
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Contact details
          _buildContactRow(Icons.email, email, textStyle),
          _buildContactRow(Icons.phone, phone, textStyle),
          _buildContactRow(Icons.location_on, location, textStyle),
          _buildContactRow(Icons.business, linkedin, textStyle),
          _buildContactRow(Icons.language, portfolio, textStyle),
        ],
      );
    }

    Widget mainContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          if (summary.isNotEmpty) ...[
            sectionHeader('Professional Summary'),
            Text(summary, style: textStyle(height: 1.5, fontSize: 14)),
          ],

          // Work Experience
          if (workExperience.isNotEmpty) ...[
            sectionHeader('Professional Experience'),
            ...workExperience.map(
              (exp) => _buildExperienceItem(exp, accentColor, textStyle),
            ),
          ],

          // Education
          if (education.isNotEmpty) ...[
            sectionHeader('Education'),
            ...education.map(
              (edu) => _buildEducationItem(edu, accentColor, textStyle),
            ),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            sectionHeader('Core Skills'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill, style: textStyle(fontSize: 12)),
                      backgroundColor: accentColor.withOpacity(0.1),
                      side: BorderSide(color: accentColor.withOpacity(0.3)),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Certifications
          if (certifications.isNotEmpty) ...[
            sectionHeader('Certifications'),
            ...certifications.map(
              (cert) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified, size: 16, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cert, style: textStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],

          // Projects
          if (projects.isNotEmpty) ...[
            sectionHeader('Projects'),
            Text(projects, style: textStyle(height: 1.5, fontSize: 14)),
          ],

          // Languages
          if (languages.isNotEmpty) ...[
            sectionHeader('Languages'),
            Text(languages, style: textStyle(height: 1.5, fontSize: 14)),
          ],

          // Hobbies
          if (hobbies.isNotEmpty) ...[
            sectionHeader('Hobbies'),
            Text(hobbies, style: textStyle(height: 1.5, fontSize: 14)),
          ],

          // References
          if (references.isNotEmpty) ...[
            sectionHeader('References'),
            Text(references, style: textStyle(height: 1.5, fontSize: 14)),
          ],
        ],
      );
    }

    // Layout-specific rendering
    switch (layout) {
      case 'Two Columns':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: contactInfo()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: mainContent()),
          ],
        );
      case 'Sidebar':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: contactInfo(),
            ),
            const SizedBox(width: 24),
            Expanded(child: mainContent()),
          ],
        );
      default: // Single Column and others
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [contactInfo(), const SizedBox(height: 16), mainContent()],
        );
    }
  }

  Widget _buildContactRow(IconData icon, String text, Function textStyle) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: textStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(
    Map<String, dynamic> exp,
    Color accentColor,
    Function textStyle,
  ) {
    final jobTitle = (exp['jobTitle'] ?? '').toString();
    final company = (exp['company'] ?? '').toString();
    final location = (exp['location'] ?? '').toString();
    final startDate = (exp['startDate'] ?? '').toString();
    final endDate = (exp['endDate'] ?? '').toString();
    final description = (exp['description'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jobTitle,
            style: textStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              company + (location.isNotEmpty ? ' • $location' : ''),
              style: textStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _formatDateRange(startDate, endDate),
              style: textStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: textStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(
    Map<String, dynamic> edu,
    Color accentColor,
    Function textStyle,
  ) {
    final degree = (edu['degree'] ?? '').toString();
    final institution =
        (edu['institution'] ?? edu['university'] ?? edu['school'] ?? '')
            .toString();
    final location = (edu['location'] ?? '').toString();
    final description = (edu['description'] ?? '').toString();
    final startDate = (edu['startDate'] ?? '').toString();
    final endDate = (edu['endDate'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            degree,
            style: textStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (institution.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(institution, style: textStyle(fontSize: 14)),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              location,
              style: textStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _formatDateRange(startDate, endDate),
              style: textStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: textStyle(fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(String startDate, String endDate) {
    String formatDate(String date) {
      if (date.isEmpty) return '';
      try {
        final dt = DateTime.tryParse(date);
        if (dt == null) return date;
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      } catch (_) {
        return date;
      }
    }

    final start = formatDate(startDate);
    final end = formatDate(endDate);

    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return '$start - Present';
    return '$start - $end';
  }

  static Color _fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
