import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import 'minimal_template_selection_screen.dart';

class MinimalResumePreviewScreen extends StatelessWidget {
  final SavedResume resume;
  final MinimalTemplateTheme theme;

  const MinimalResumePreviewScreen({
    super.key,
    required this.resume,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(
        int.parse('0xFF${theme.backgroundColor.substring(1)}'),
      ),
      appBar: AppBar(
        title: Text('Preview - ${theme.name}'),
        backgroundColor: Color(
          int.parse('0xFF${theme.primaryColor.substring(1)}'),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Green Header Section
          _buildProfessionalHeader(),

          // White Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactInfo(),
                  const SizedBox(height: 24),
                  _buildSummary(),
                  const SizedBox(height: 24),
                  _buildSkills(),
                  const SizedBox(height: 24),
                  _buildWorkExperience(),
                  const SizedBox(height: 24),
                  _buildEducation(),
                  const SizedBox(height: 24),
                  _buildAdditionalSections(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: Color(
          int.parse('0xFF${theme.primaryColor.substring(1)}'),
        ),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Theme'),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    final name = resume.data['name'] ?? 'Your Name';
    final jobTitle = resume.data['jobTitle'] ?? resume.data['title'] ?? '';
    final email = resume.data['email'] ?? '';
    final phone = resume.data['phone'] ?? '';

    return Container(
      height: 140,
      color: Color(int.parse('0xFF${theme.primaryColor.substring(1)}')),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Profile Photo Placeholder (circular)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'Y',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    int.parse('0xFF${theme.primaryColor.substring(1)}'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Name and Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    jobTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (email.isNotEmpty || phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (email.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (email.isNotEmpty && phone.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Container(width: 1, height: 12, color: Colors.white),
                        const SizedBox(width: 16),
                      ],
                      if (phone.isNotEmpty) ...[
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
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

  Widget _buildContactInfo() {
    final linkedin = resume.data['linkedIn'] ?? resume.data['linkedin'] ?? '';
    final website = resume.data['website'] ?? '';
    final address = resume.data['address'] ?? '';

    if (linkedin.isEmpty && website.isEmpty && address.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Contact Information'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (linkedin.isNotEmpty)
              _buildContactItem(Icons.business, 'LinkedIn: $linkedin'),
            if (website.isNotEmpty)
              _buildContactItem(Icons.web, 'Website: $website'),
            if (address.isNotEmpty)
              _buildContactItem(Icons.location_on, 'Address: $address'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Color(int.parse('0xFF${theme.accentColor.substring(1)}')),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Color(int.parse('0xFF${theme.textColor.substring(1)}')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final summary = resume.data['summary'] ?? resume.data['objective'] ?? '';

    if (summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Professional Summary'),
        const SizedBox(height: 12),
        Text(
          summary,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(int.parse('0xFF${theme.textColor.substring(1)}')),
          ),
        ),
      ],
    );
  }

  Widget _buildSkills() {
    final skills = resume.data['skills'] ?? '';

    if (skills.isEmpty) return const SizedBox.shrink();

    final skillsList = skills
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty as bool)
        .toList();

    if (skillsList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skillsList
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse('0xFF${theme.accentColor.substring(1)}'),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(
                        int.parse('0xFF${theme.accentColor.substring(1)}'),
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(
                        int.parse('0xFF${theme.primaryColor.substring(1)}'),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildWorkExperience() {
    final workExperiencesJson = resume.data['workExperiences'] ?? '';

    if (workExperiencesJson.isEmpty) return const SizedBox.shrink();

    List<dynamic> experiences;
    try {
      experiences = jsonDecode(workExperiencesJson);
    } catch (e) {
      return const SizedBox.shrink();
    }

    if (experiences.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Work Experience'),
        const SizedBox(height: 16),
        ...experiences.map((exp) => _buildExperienceItem(exp)),
      ],
    );
  }

  Widget _buildExperienceItem(dynamic experience) {
    final jobTitle = experience['jobTitle'] ?? '';
    final company = experience['company'] ?? '';
    final startDate = experience['startDate'] ?? '';
    final endDate = experience['endDate'] ?? '';
    final description = experience['description'] ?? '';
    final achievements = experience['achievements'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse('0xFF${theme.accentColor.substring(1)}'),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          int.parse('0xFF${theme.primaryColor.substring(1)}'),
                        ),
                      ),
                    ),
                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(
                            int.parse(
                              '0xFF${theme.secondaryColor.substring(1)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${startDate.isNotEmpty ? startDate : ''} - ${endDate.isNotEmpty ? endDate : 'Present'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(
                            int.parse('0xFF${theme.textColor.substring(1)}'),
                          ).withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(
                            int.parse('0xFF${theme.textColor.substring(1)}'),
                          ),
                        ),
                      ),
                    ],
                    if (achievements.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        achievements,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(
                            int.parse('0xFF${theme.textColor.substring(1)}'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducation() {
    final educationsJson = resume.data['educations'] ?? '';

    if (educationsJson.isEmpty) return const SizedBox.shrink();

    List<dynamic> educations;
    try {
      educations = jsonDecode(educationsJson);
    } catch (e) {
      return const SizedBox.shrink();
    }

    if (educations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education'),
        const SizedBox(height: 16),
        ...educations.map((edu) => _buildEducationItem(edu)),
      ],
    );
  }

  Widget _buildEducationItem(dynamic education) {
    final degree = education['degree'] ?? '';
    final institution =
        education['institution'] ??
        education['university'] ??
        education['school'] ??
        '';
    final startDate = education['startDate'] ?? '';
    final endDate = education['endDate'] ?? '';
    final description = education['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${theme.accentColor.substring(1)}')),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(
                      int.parse('0xFF${theme.primaryColor.substring(1)}'),
                    ),
                  ),
                ),
                if (institution.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    institution,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(
                        int.parse('0xFF${theme.secondaryColor.substring(1)}'),
                      ),
                    ),
                  ),
                ],
                if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${startDate.isNotEmpty ? startDate : ''} - ${endDate.isNotEmpty ? endDate : 'Present'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(
                        int.parse('0xFF${theme.textColor.substring(1)}'),
                      ).withOpacity(0.7),
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(
                        int.parse('0xFF${theme.textColor.substring(1)}'),
                      ),
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

  Widget _buildAdditionalSections() {
    final languages = resume.data['languages'] ?? '';
    final hobbies = resume.data['hobbies'] ?? '';
    final certifications = resume.data['certifications'] ?? '';

    if (languages.isEmpty && hobbies.isEmpty && certifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (languages.isNotEmpty) ...[
          _buildSimpleSection('Languages', languages),
          const SizedBox(height: 16),
        ],
        if (certifications.isNotEmpty) ...[
          _buildSimpleSection('Certifications', certifications),
          const SizedBox(height: 16),
        ],
        if (hobbies.isNotEmpty) ...[
          _buildSimpleSection('Interests & Hobbies', hobbies),
        ],
      ],
    );
  }

  Widget _buildSimpleSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(int.parse('0xFF${theme.textColor.substring(1)}')),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(int.parse('0xFF${theme.accentColor.substring(1)}')),
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(int.parse('0xFF${theme.primaryColor.substring(1)}')),
        ),
      ),
    );
  }
}
