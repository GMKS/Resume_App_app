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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.data['name'] ?? 'Your Name',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resume.data['jobTitle'] ?? 'Your Job Title',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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

    if (resume.data['email']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem(Icons.email, resume.data['email']));
    }
    if (resume.data['phone']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem(Icons.phone, resume.data['phone']));
    }
    if (resume.data['location']?.toString().isNotEmpty == true) {
      contactItems.add(
        _buildContactItem(Icons.location_on, resume.data['location']),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  Widget _buildAdditionalContact() {
    final contactItems = <Widget>[];

    if (resume.data['linkedin']?.toString().isNotEmpty == true) {
      contactItems.add(
        _buildContactItem(Icons.business, resume.data['linkedin']),
      );
    }
    if (resume.data['github']?.toString().isNotEmpty == true) {
      contactItems.add(_buildContactItem(Icons.code, resume.data['github']));
    }
    if (resume.data['website']?.toString().isNotEmpty == true) {
      contactItems.add(
        _buildContactItem(Icons.language, resume.data['website']),
      );
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
          if (exp['description']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              exp['description'],
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

    if (resume.data['workTimeline'] is List) {
      for (final item in resume.data['workTimeline']) {
        if (item is Map<String, dynamic>) {
          experience.add(item);
        }
      }
    }

    return experience;
  }

  List<Map<String, dynamic>> _getEducation() {
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
}
