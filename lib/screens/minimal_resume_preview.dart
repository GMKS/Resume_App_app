import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';

class MinimalResumePreview extends StatelessWidget {
  final SavedResume resume;
  final String? templateId;

  const MinimalResumePreview({
    super.key,
    required this.resume,
    this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    final data = resume.data;

    // Extract basic information
    final name = (data['name'] ?? data['full_name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final website = (data['website'] ?? '').toString();
    final summary = (data['summary'] ?? '').toString();
    final skillsCsv = (data['skills'] ?? '').toString();

    final work = _parseWork(data['workExperiences']);
    final edus = _parseEducation(data['educations']);

    // Template-specific styling based on templateId
    final templateStyle = _getTemplateStyle(templateId);

    return Scaffold(
      backgroundColor: templateStyle.backgroundColor,
      appBar: AppBar(
        title: Text(templateStyle.templateName),
        backgroundColor: templateStyle.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Resume',
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) =>
                    route.settings.name == null ||
                    route.isFirst ||
                    route.settings.arguments?.toString().contains(
                          'MinimalResumeFormScreen',
                        ) ==
                        true,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_outlined),
            onSelected: (v) async {
              if (!await PremiumService.isPremiumWithDialog(context)) return;
              if (v == 'EMAIL') {
                await ShareExportService(context).shareViaEmail(resume);
              } else if (v == 'WHATSAPP') {
                await ShareExportService(context).shareViaWhatsApp(resume);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'EMAIL',
                child: ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'WHATSAPP',
                child: ListTile(
                  leading: Icon(Icons.message_outlined),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (v) async {
              if (v == 'PDF') {
                await ShareExportService(context).exportAndOpenPdf(resume);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'PDF',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Export as PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 595, // A4 width in logical pixels
            maxHeight: 842, // A4 height in logical pixels
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(
                        name,
                        email,
                        phone,
                        location,
                        website,
                        templateStyle,
                      ),

                      // Summary Section
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          'Professional Summary',
                          summary,
                          templateStyle,
                        ),
                      ],

                      // Skills Section
                      if (skillsCsv.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSkillsSection(skillsCsv, templateStyle),
                      ],

                      // Work Experience Section
                      if (work.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildWorkSection(work, templateStyle),
                      ],

                      // Education Section
                      if (edus.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildEducationSection(edus, templateStyle),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String name,
    String email,
    String phone,
    String location,
    String website,
    TemplateStyle style,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: style.headerFontSize,
            fontWeight: FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (email.isNotEmpty) ...[
              Icon(Icons.email_outlined, size: 16, color: style.secondaryColor),
              const SizedBox(width: 4),
              Text(email, style: TextStyle(color: style.textColor)),
              const SizedBox(width: 16),
            ],
            if (phone.isNotEmpty) ...[
              Icon(Icons.phone_outlined, size: 16, color: style.secondaryColor),
              const SizedBox(width: 4),
              Text(phone, style: TextStyle(color: style.textColor)),
              const SizedBox(width: 16),
            ],
            if (location.isNotEmpty) ...[
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: style.secondaryColor,
              ),
              const SizedBox(width: 4),
              Text(location, style: TextStyle(color: style.textColor)),
            ],
          ],
        ),
        if (website.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.language_outlined,
                size: 16,
                color: style.secondaryColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  website,
                  style: TextStyle(color: style.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, String content, TemplateStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: style.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: style.accentColor),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: style.bodyFontSize,
            color: style.textColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(String skillsCsv, TemplateStyle style) {
    final skills = skillsCsv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: TextStyle(
            fontSize: style.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: style.accentColor),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: style.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: style.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: style.bodyFontSize - 1,
                      color: style.textColor,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildWorkSection(
    List<Map<String, dynamic>> work,
    TemplateStyle style,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Experience',
          style: TextStyle(
            fontSize: style.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: style.accentColor),
        const SizedBox(height: 12),
        ...work.map(
          (exp) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp['jobTitle'] ?? '',
                  style: TextStyle(
                    fontSize: style.bodyFontSize + 1,
                    fontWeight: FontWeight.bold,
                    color: style.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exp['company'] ?? ''} • ${exp['location'] ?? ''}',
                  style: TextStyle(
                    fontSize: style.bodyFontSize,
                    color: style.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(exp['startDate'])} - ${_formatDate(exp['endDate']) ?? 'Present'}',
                  style: TextStyle(
                    fontSize: style.bodyFontSize - 1,
                    color: style.textColor.withOpacity(0.7),
                  ),
                ),
                if ((exp['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    exp['description'],
                    style: TextStyle(
                      fontSize: style.bodyFontSize,
                      color: style.textColor,
                      height: 1.4,
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

  Widget _buildEducationSection(
    List<Map<String, dynamic>> edus,
    TemplateStyle style,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Education',
          style: TextStyle(
            fontSize: style.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 50, color: style.accentColor),
        const SizedBox(height: 12),
        ...edus.map(
          (edu) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu['degree'] ?? '',
                  style: TextStyle(
                    fontSize: style.bodyFontSize + 1,
                    fontWeight: FontWeight.bold,
                    color: style.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edu['institution'] ??
                      edu['university'] ??
                      edu['school'] ??
                      '',
                  style: TextStyle(
                    fontSize: style.bodyFontSize,
                    color: style.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(edu['startDate'])} - ${_formatDate(edu['endDate']) ?? 'Present'}',
                  style: TextStyle(
                    fontSize: style.bodyFontSize - 1,
                    color: style.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parseWork(dynamic workData) {
    if (workData == null || workData.toString().isEmpty) return [];
    try {
      if (workData is String) {
        final List<dynamic> decoded = jsonDecode(workData);
        return decoded.cast<Map<String, dynamic>>();
      } else if (workData is List) {
        return workData.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error parsing work data: $e');
    }
    return [];
  }

  List<Map<String, dynamic>> _parseEducation(dynamic eduData) {
    if (eduData == null || eduData.toString().isEmpty) return [];
    try {
      if (eduData is String) {
        final List<dynamic> decoded = jsonDecode(eduData);
        return decoded.cast<Map<String, dynamic>>();
      } else if (eduData is List) {
        return eduData.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error parsing education data: $e');
    }
    return [];
  }

  TemplateStyle _getTemplateStyle(String? templateId) {
    switch (templateId) {
      case 'minimal_1':
        return const TemplateStyle(
          templateName: 'Clean Minimal',
          primaryColor: Color(0xFF2C3E50),
          secondaryColor: Color(0xFF34495E),
          accentColor: Color(0xFF3498DB),
          backgroundColor: Colors.white,
          textColor: Color(0xFF2C3E50),
          headerFontSize: 32,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
      case 'minimal_2':
        return const TemplateStyle(
          templateName: 'Modern Minimal',
          primaryColor: Color(0xFF1A365D),
          secondaryColor: Color(0xFF2D3748),
          accentColor: Color(0xFF4299E1),
          backgroundColor: Colors.white,
          textColor: Color(0xFF1A202C),
          headerFontSize: 28,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
      case 'minimal_3':
        return const TemplateStyle(
          templateName: 'Professional Minimal',
          primaryColor: Color(0xFF4A5568),
          secondaryColor: Color(0xFF718096),
          accentColor: Color(0xFF38B2AC),
          backgroundColor: Colors.white,
          textColor: Color(0xFF2D3748),
          headerFontSize: 30,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
      case 'minimal_4':
        return const TemplateStyle(
          templateName: 'Elegant Minimal',
          primaryColor: Color(0xFF6B46C1),
          secondaryColor: Color(0xFF805AD5),
          accentColor: Color(0xFF9F7AEA),
          backgroundColor: Color(0xFFFAF5FF),
          textColor: Color(0xFF2D3748),
          headerFontSize: 28,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
      case 'minimal_5':
        return const TemplateStyle(
          templateName: 'Corporate Minimal',
          primaryColor: Color(0xFF1F2937),
          secondaryColor: Color(0xFF374151),
          accentColor: Color(0xFF10B981),
          backgroundColor: Colors.white,
          textColor: Color(0xFF111827),
          headerFontSize: 30,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
      default:
        return const TemplateStyle(
          templateName: 'Minimal Preview',
          primaryColor: Color(0xFF6C5CE7),
          secondaryColor: Color(0xFF5A4FCF),
          accentColor: Color(0xFF74B9FF),
          backgroundColor: Colors.white,
          textColor: Color(0xFF333333),
          headerFontSize: 28,
          sectionTitleFontSize: 16,
          bodyFontSize: 12,
        );
    }
  }

  String? _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) return null;

    String dateStr = dateValue.toString();

    // Remove time portion if present (00:00:00.000)
    if (dateStr.contains('T')) {
      dateStr = dateStr.split('T')[0];
    }
    if (dateStr.contains(' ')) {
      dateStr = dateStr.split(' ')[0];
    }

    // Try to parse and reformat
    try {
      final DateTime date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      // If parsing fails, return the original string if it's not just zeros
      if (dateStr.replaceAll(RegExp(r'[0\-:]'), '').isEmpty) {
        return null;
      }
      return dateStr;
    }
  }
}

class TemplateStyle {
  final String templateName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final double headerFontSize;
  final double sectionTitleFontSize;
  final double bodyFontSize;

  const TemplateStyle({
    required this.templateName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    this.headerFontSize = 28,
    this.sectionTitleFontSize = 18,
    this.bodyFontSize = 14,
  });
}
