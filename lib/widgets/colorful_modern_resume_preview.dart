import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../screens/modern_template_selection_screen.dart';

class ColorfulModernResumePreview extends StatelessWidget {
  final SavedResume resume;
  final ModernTemplateTheme theme;

  const ColorfulModernResumePreview({
    super.key,
    required this.resume,
    required this.theme,
  });

  // Helper method to convert hex string to Color
  Color get primaryColor =>
      Color(int.parse(theme.primaryColor.substring(1), radix: 16) + 0xFF000000);

  @override
  Widget build(BuildContext context) {
    // Extract personal info
    final personalInfo =
        resume.data['personalInfo'] as Map<String, dynamic>? ?? {};
    final name =
        personalInfo['name']?.toString() ??
        resume.data['name']?.toString() ??
        'Your Name';
    final jobTitle = resume.data['jobTitle']?.toString() ?? 'Your Job Title';

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with theme color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Profile Photo
                  if (personalInfo['profilePhotoBase64']
                          ?.toString()
                          .isNotEmpty ==
                      true)
                    Container(
                      margin: const EdgeInsets.only(right: 24),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: DecorationImage(
                          image: MemoryImage(
                            base64Decode(personalInfo['profilePhotoBase64']),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  // Name and Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildContactInfo()),
                const SizedBox(width: 24),
                Expanded(child: _buildAdditionalContact()),
              ],
            ),
            const SizedBox(height: 24),

            // Professional Summary
            if (resume.data['summary']?.toString().isNotEmpty == true)
              _buildSection(
                'Professional Summary',
                Text(
                  resume.data['summary'],
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),

            // Work Experience
            if (_getWorkExperience().isNotEmpty)
              _buildSection(
                'Work Experience',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getWorkExperience()
                      .map((exp) => _buildWorkExperience(exp))
                      .toList(),
                ),
              ),

            // Education
            if (_getEducation().isNotEmpty)
              _buildSection(
                'Education',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getEducation()
                      .map((edu) => _buildEducation(edu))
                      .toList(),
                ),
              ),

            // Skills
            if (_getSkills().isNotEmpty)
              _buildSection(
                'Skills',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getSkills()
                      .map((skill) => _buildSkillChip(skill))
                      .toList(),
                ),
              ),

            // Certifications
            if (_getCertifications().isNotEmpty)
              _buildSection(
                'Certifications',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getCertifications()
                      .map((cert) => _buildCertification(cert))
                      .toList(),
                ),
              ),

            // Achievements
            if (resume.data['achievements']?.toString().isNotEmpty == true)
              _buildSection(
                'Achievements',
                Text(
                  resume.data['achievements'],
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),

            // Hobbies
            if (resume.data['hobbies']?.toString().isNotEmpty == true)
              _buildSection(
                'Hobbies',
                Text(
                  resume.data['hobbies'],
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),

            // Custom Fields - Display as list
            if (resume.data['customFields'] is List &&
                (resume.data['customFields'] as List).isNotEmpty)
              _buildSection(
                'Additional Information',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (resume.data['customFields'] as List)
                      .map(
                        (field) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, size: 8, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  field.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            border: Border(left: BorderSide(color: primaryColor, width: 4)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.only(left: 16), child: content),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactInfo() {
    final contactItems = <Widget>[];
    final personalInfo =
        resume.data['personalInfo'] as Map<String, dynamic>? ?? {};

    final email =
        personalInfo['email']?.toString() ??
        resume.data['email']?.toString() ??
        '';
    final phone =
        personalInfo['phone']?.toString() ??
        resume.data['phone']?.toString() ??
        '';
    final location =
        personalInfo['location']?.toString() ??
        resume.data['location']?.toString() ??
        '';

    if (email.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.email, email));
    }
    if (phone.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.phone, phone));
    }
    if (location.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.location_on, location));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  Widget _buildAdditionalContact() {
    final contactItems = <Widget>[];
    final personalInfo =
        resume.data['personalInfo'] as Map<String, dynamic>? ?? {};

    final linkedin =
        personalInfo['linkedin']?.toString() ??
        resume.data['linkedin']?.toString() ??
        '';
    final github =
        personalInfo['github']?.toString() ??
        resume.data['github']?.toString() ??
        '';
    final website =
        personalInfo['website']?.toString() ??
        resume.data['website']?.toString() ??
        '';

    if (linkedin.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.business, linkedin));
    }
    if (github.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.code, github));
    }
    if (website.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.language, website));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildWorkExperience(Map<String, dynamic> exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exp['role'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatDateRange(exp['start'], exp['end']),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exp['company'] ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          if (((exp['description'] ?? '') as String).trim().isNotEmpty ||
              ((exp['summary'] ?? '') as String).trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ((exp['description'] ?? '').toString().trim().isNotEmpty)
                  ? exp['description']
                  : (exp['summary']?.toString() ?? ''),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducation(Map<String, dynamic> edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  edu['degree'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatDateRange(edu['start'], edu['end']),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            edu['school'] ?? edu['college'] ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        skill.trim(),
        style: TextStyle(
          fontSize: 12,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWorkExperience() {
    final List<Map<String, dynamic>> experience = [];

    // Try multiple possible keys for work experience
    final workData =
        resume.data['workTimeline'] ?? resume.data['workExperience'] ?? [];

    if (workData is List) {
      for (final item in workData) {
        if (item is Map<String, dynamic>) {
          experience.add(item);
        }
      }
    }

    return experience;
  }

  List<Map<String, dynamic>> _getEducation() {
    final List<Map<String, dynamic>> education = [];

    // Try multiple possible keys for education
    final eduData =
        resume.data['eduTimeline'] ?? resume.data['education'] ?? [];

    if (eduData is List) {
      for (final item in eduData) {
        if (item is Map<String, dynamic>) {
          education.add(item);
        }
      }
    }

    return education;
  }

  List<String> _getSkills() {
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

  String _formatDateRange(dynamic start, dynamic end) {
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

  List<String> _getCertifications() {
    final List<String> certifications = [];

    if (resume.data['certifications'] is String &&
        resume.data['certifications'].toString().isNotEmpty) {
      certifications.addAll(
        resume.data['certifications']
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    } else if (resume.data['certificationsList'] is List) {
      for (final cert in resume.data['certificationsList']) {
        if (cert.toString().isNotEmpty) {
          certifications.add(cert.toString().trim());
        }
      }
    }

    return certifications;
  }

  Widget _buildCertification(String certification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              certification,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
