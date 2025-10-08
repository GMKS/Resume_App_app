import 'package:flutter/material.dart';
import '../models/customize_settings.dart';
import '../models/custom_resume_data.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';

class CustomResumePreview extends StatelessWidget {
  final CustomizeSettings settings;
  final CustomResumeData resumeData;

  const CustomResumePreview({
    super.key,
    required this.settings,
    required this.resumeData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        backgroundColor: _getThemeColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Edit Resume',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveResume(context),
            tooltip: 'Save Resume',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(24),
          child: _buildLayoutBasedContent(),
        ),
      ),
    );
  }

  Widget _buildLayoutBasedContent() {
    switch (settings.layoutType) {
      case 'Single Column':
        return _buildSingleColumnLayout();
      case 'Two Column':
        return _buildTwoColumnLayout();
      case 'Grid':
        return _buildGridLayout();
      default:
        return _buildSingleColumnLayout();
    }
  }

  Widget _buildSingleColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        if (resumeData.summary.isNotEmpty) ...[
          _buildSection('PROFESSIONAL SUMMARY', resumeData.summary),
          const SizedBox(height: 20),
        ],
        if (resumeData.experience.isNotEmpty) ...[
          _buildExperienceSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.education.isNotEmpty) ...[
          _buildEducationSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.skills.isNotEmpty) ...[
          _buildSkillsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.projects.isNotEmpty) ...[
          _buildProjectsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.certifications.isNotEmpty) ...[
          _buildCertificationsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.languages.isNotEmpty) ...[
          _buildLanguagesSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.achievements.isNotEmpty) ...[
          _buildAchievementsSection(),
          const SizedBox(height: 20),
        ],
        if (resumeData.showReferences && resumeData.references.isNotEmpty) ...[
          _buildReferencesSection(),
        ],
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar (30%)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactContactInfo(),
                  const SizedBox(height: 20),
                  if (resumeData.skills.isNotEmpty) ...[
                    _buildSkillsSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.education.isNotEmpty) ...[
                    _buildEducationSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.languages.isNotEmpty) ...[
                    _buildLanguagesSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.certifications.isNotEmpty) ...[
                    _buildCertificationsSection(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Main content (70%)
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resumeData.summary.isNotEmpty) ...[
                    _buildSection('PROFESSIONAL SUMMARY', resumeData.summary),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.experience.isNotEmpty) ...[
                    _buildExperienceSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.projects.isNotEmpty) ...[
                    _buildProjectsSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.achievements.isNotEmpty) ...[
                    _buildAchievementsSection(),
                    const SizedBox(height: 20),
                  ],
                  if (resumeData.showReferences &&
                      resumeData.references.isNotEmpty) ...[
                    _buildReferencesSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        if (resumeData.summary.isNotEmpty) ...[
          _buildSection('PROFESSIONAL SUMMARY', resumeData.summary),
          const SizedBox(height: 20),
        ],
        // First row of grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeData.skills.isNotEmpty)
              Expanded(child: _buildSkillsSection()),
            if (resumeData.skills.isNotEmpty &&
                resumeData.experience.isNotEmpty)
              const SizedBox(width: 12),
            if (resumeData.experience.isNotEmpty)
              Expanded(child: _buildExperienceSection()),
            if (resumeData.experience.isNotEmpty &&
                resumeData.education.isNotEmpty)
              const SizedBox(width: 12),
            if (resumeData.education.isNotEmpty)
              Expanded(child: _buildEducationSection()),
          ],
        ),
        const SizedBox(height: 20),
        // Second row of grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumeData.projects.isNotEmpty)
              Expanded(child: _buildProjectsSection()),
            if (resumeData.projects.isNotEmpty &&
                resumeData.certifications.isNotEmpty)
              const SizedBox(width: 12),
            if (resumeData.certifications.isNotEmpty)
              Expanded(child: _buildCertificationsSection()),
            if (resumeData.certifications.isNotEmpty &&
                resumeData.languages.isNotEmpty)
              const SizedBox(width: 12),
            if (resumeData.languages.isNotEmpty)
              Expanded(child: _buildLanguagesSection()),
          ],
        ),
        if (resumeData.achievements.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildAchievementsSection(),
        ],
        if (resumeData.showReferences && resumeData.references.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildReferencesSection(),
        ],
      ],
    );
  }

  Widget _buildCompactContactInfo() {
    final contact = resumeData.contactInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 30, color: _getThemeColor()),
        const SizedBox(height: 12),
        if (contact.email.isNotEmpty) ...[
          _buildCompactContactItem(Icons.email, contact.email),
          const SizedBox(height: 6),
        ],
        if (contact.phone.isNotEmpty) ...[
          _buildCompactContactItem(Icons.phone, contact.phone),
          const SizedBox(height: 6),
        ],
        if (contact.location.isNotEmpty) ...[
          _buildCompactContactItem(Icons.location_on, contact.location),
          const SizedBox(height: 6),
        ],
        if (contact.website.isNotEmpty) ...[
          _buildCompactContactItem(Icons.web, contact.website),
          const SizedBox(height: 6),
        ],
        if (contact.linkedin.isNotEmpty) ...[
          _buildCompactContactItem(Icons.business, contact.linkedin),
        ],
      ],
    );
  }

  Widget _buildCompactContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _getThemeColor()),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Color _getThemeColor() {
    switch (settings.colorTheme) {
      case '#2196F3':
        return Colors.blue;
      case '#4CAF50':
        return Colors.green;
      case '#F44336':
        return Colors.red;
      case '#9C27B0':
        return Colors.purple;
      case '#FF9800':
        return Colors.orange;
      case '#009688':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resumeData.fullName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        if (resumeData.jobTitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            resumeData.jobTitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildContactInfo(),
      ],
    );
  }

  Widget _buildContactInfo() {
    final contact = resumeData.contactInfo;
    final contactItems = <Widget>[];

    if (contact.email.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.email, contact.email));
    }
    if (contact.phone.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.phone, contact.phone));
    }
    if (contact.location.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.location_on, contact.location));
    }
    if (contact.website.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.web, contact.website));
    }
    if (contact.linkedin.isNotEmpty) {
      contactItems.add(_buildContactItem(Icons.business, contact.linkedin));
    }

    return Wrap(spacing: 16, runSpacing: 8, children: contactItems);
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORK EXPERIENCE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.experience.map(
          (exp) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.jobTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exp.companyName} | ${_formatDateRange(exp.startDate, exp.endDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (exp.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    exp.location,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
                if (exp.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    exp.description,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDUCATION',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.education.map(
          (edu) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${edu.institution} | ${_formatDateRange(edu.startDate, edu.endDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (edu.gpa != null && edu.gpa!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'GPA: ${edu.gpa}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
                if (edu.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    edu.description,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILLS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resumeData.skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getThemeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getThemeColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: _getThemeColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECTS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.projects.map(
          (project) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (project.projectUrl != null &&
                    project.projectUrl!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    project.projectUrl!,
                    style: TextStyle(fontSize: 13, color: _getThemeColor()),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  project.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                if (project.technologies.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Technologies: ${project.technologies.join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CERTIFICATIONS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.certifications.map(
          (cert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cert.issuer} | ${_formatDate(cert.issueDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUAGES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.languages.map(
          (lang) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${lang.name} - ${lang.proficiency}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACHIEVEMENTS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: _getThemeColor(), fontSize: 16),
                ),
                Expanded(
                  child: Text(
                    achievement.description,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFERENCES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: _getThemeColor()),
        const SizedBox(height: 12),
        ...resumeData.references.map(
          (ref) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ref.title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  '${ref.email} | ${ref.phone}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startStr = _formatDate(start);
    if (end == null) return '$startStr - Present';
    return '$startStr - ${_formatDate(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.year}';
  }

  Future<void> _saveResume(BuildContext context) async {
    try {
      // Convert CustomResumeData to SavedResume format
      final resumeData = {
        'full_name': this.resumeData.fullName,
        'job_title': this.resumeData.jobTitle,
        'email': this.resumeData.contactInfo.email,
        'phone': this.resumeData.contactInfo.phone,
        'location': this.resumeData.contactInfo.location,
        'website': this.resumeData.contactInfo.website,
        'linkedin': this.resumeData.contactInfo.linkedin,
        'summary': this.resumeData.summary,
        'skills': this.resumeData.skills.map((s) => s.name).join(', '),
        'work_experience': this.resumeData.experience
            .map((e) => e.toJson())
            .toList(),
        'education': this.resumeData.education.map((e) => e.toJson()).toList(),
        'projects': this.resumeData.projects.map((p) => p.toJson()).toList(),
        'certifications': this.resumeData.certifications
            .map((c) => c.toJson())
            .toList(),
        'languages': this.resumeData.languages.map((l) => l.toJson()).toList(),
        'achievements': this.resumeData.achievements
            .map((a) => a.toJson())
            .toList(),
        'references': this.resumeData.references
            .map((r) => r.toJson())
            .toList(),
        'show_references': this.resumeData.showReferences,
        'color_scheme': settings.colorTheme,
        'font_family': settings.fontFamily,
        'template': 'Custom',
      };

      final resume = SavedResume(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title:
            '${this.resumeData.fullName.isNotEmpty ? this.resumeData.fullName : 'Custom'} Resume',
        template: 'Custom',
        data: resumeData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Here you would typically save using ResumeStorageService
      await ResumeStorageService.instance.saveOrUpdate(resume);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save resume: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
