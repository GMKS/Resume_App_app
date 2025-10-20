import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../services/share_export_service.dart';

class SmartAssistResultPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> aiGeneratedData;

  const SmartAssistResultPreviewScreen({
    super.key,
    required this.aiGeneratedData,
  });

  @override
  Widget build(BuildContext context) {
    final personalInfo = aiGeneratedData['personalInfo'] as Map? ?? {};
    final name = personalInfo['name']?.toString() ?? 'No name extracted';
    final email = personalInfo['email']?.toString() ?? '';
    final phone = personalInfo['phone']?.toString() ?? '';
    final location = personalInfo['location']?.toString() ?? '';
    final linkedIn = personalInfo['linkedin']?.toString() ?? '';
    final summary = aiGeneratedData['summary']?.toString() ?? '';
    final coreSkills = aiGeneratedData['coreSkills']?.toString() ?? '';
    final technicalSkills = aiGeneratedData['technicalSkills'] as Map? ?? {};
    final workExperience = aiGeneratedData['workExperience'] as List? ?? [];
    final education = aiGeneratedData['education'] as List? ?? [];
    final achievements = aiGeneratedData['achievements']?.toString() ?? '';
    final personalDetails = aiGeneratedData['personalDetails'] as Map? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onSelected: (value) async {
              await _handleShare(context, value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'email',
                child: ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: ListTile(
                  leading: Icon(Icons.message_outlined),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Resume',
            onPressed: () => _handleSave(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSidebarTitle('CURRICULUM VITAE'),
                            const SizedBox(height: 20),
                            _buildSidebarTitle('PERSONAL INFORMATION'),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (email.isNotEmpty)
                              _buildInfoRow(Icons.email_outlined, email),
                            if (phone.isNotEmpty)
                              _buildInfoRow(Icons.phone_outlined, phone),
                            if (location.isNotEmpty)
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                location,
                              ),
                            if (linkedIn.isNotEmpty)
                              _buildInfoRow(Icons.link, linkedIn),
                            const SizedBox(height: 20),
                            if (summary.isNotEmpty) ...[
                              _buildSidebarTitle('PROFESSIONAL SUMMARY'),
                              const SizedBox(height: 12),
                              Text(
                                summary.length > 300
                                    ? '${summary.substring(0, 300)}...'
                                    : summary,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (coreSkills.isNotEmpty) ...[
                              _buildSidebarTitle('CORE SKILLS'),
                              const SizedBox(height: 12),
                              Text(
                                coreSkills,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (education.isNotEmpty) ...[
                              _buildSidebarTitle('EDUCATION'),
                              const SizedBox(height: 12),
                              ...education.map((edu) {
                                final degree = edu['degree']?.toString() ?? '';
                                final school = edu['school']?.toString() ?? '';
                                final start = edu['start']?.toString() ?? '';
                                final end = edu['end']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (degree.isNotEmpty)
                                        Text(
                                          degree,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                      if (school.isNotEmpty)
                                        Text(
                                          school,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      if (start.isNotEmpty || end.isNotEmpty)
                                        Text(
                                          '${_formatYear(start)}-${_formatYear(end)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            if (achievements.isNotEmpty) ...[
                              _buildSidebarTitle('ACHIEVEMENTS'),
                              const SizedBox(height: 12),
                              Text(
                                achievements,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (technicalSkills.isNotEmpty) ...[
                              _buildSidebarTitle('TECHNICAL SKILLS'),
                              const SizedBox(height: 12),
                              ...technicalSkills.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.key}:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            if (personalDetails.isNotEmpty) ...[
                              _buildSidebarTitle('PERSONAL DETAILS'),
                              const SizedBox(height: 12),
                              ...personalDetails.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (workExperience.isNotEmpty) ...[
                              _buildMainTitle('PROFESSIONAL EXPERIENCE'),
                              const SizedBox(height: 16),
                              ...workExperience.map((work) {
                                final role = work['role']?.toString() ?? '';
                                final company =
                                    work['company']?.toString() ?? '';
                                final workLocation =
                                    work['location']?.toString() ?? '';
                                final start = work['start']?.toString() ?? '';
                                final end = work['end']?.toString() ?? '';
                                final currentlyWorking =
                                    work['currentlyWorking'] == true;
                                final duration =
                                    work['duration']?.toString() ?? '';
                                final teamSize =
                                    work['teamSize']?.toString() ?? '';
                                final tools = work['tools']?.toString() ?? '';
                                final responsibilities =
                                    work['responsibilities'] as List? ?? [];
                                final projects =
                                    work['projects'] as List? ?? [];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (role.isNotEmpty)
                                        Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (company.isNotEmpty)
                                        Text(
                                          company +
                                              (workLocation.isNotEmpty
                                                  ? ' | $workLocation'
                                                  : ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      if (start.isNotEmpty ||
                                          end.isNotEmpty ||
                                          currentlyWorking ||
                                          duration.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            duration.isNotEmpty
                                                ? duration
                                                : '${_formatYear(start)}-${currentlyWorking ? "Present" : _formatYear(end)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      if (teamSize.isNotEmpty ||
                                          tools.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            [
                                              if (teamSize.isNotEmpty)
                                                'Team Size: $teamSize',
                                              if (tools.isNotEmpty)
                                                'Tools: $tools',
                                            ].join(' | '),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      if (responsibilities.isNotEmpty) ...[
                                        Text(
                                          'Key Responsibilities:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...responsibilities.map(
                                          (resp) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    resp.toString(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      height: 1.4,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (projects.isNotEmpty) ...[
                                        Text(
                                          'Projects:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...projects.map((project) {
                                          final projectName =
                                              project['name']?.toString() ?? '';
                                          final projectDesc =
                                              project['description']
                                                  ?.toString() ??
                                              '';
                                          final projectRole =
                                              project['role']?.toString() ?? '';
                                          final projectDuration =
                                              project['duration']?.toString() ??
                                              '';
                                          final projectSkills =
                                              project['skills']?.toString() ??
                                              '';

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              bottom: 12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (projectName.isNotEmpty)
                                                  Text(
                                                    '▪ $projectName',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade900,
                                                    ),
                                                  ),
                                                if (projectRole.isNotEmpty ||
                                                    projectDuration.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Text(
                                                      [
                                                        if (projectRole
                                                            .isNotEmpty)
                                                          'Role: $projectRole',
                                                        if (projectDuration
                                                            .isNotEmpty)
                                                          'Duration: $projectDuration',
                                                      ].join(' | '),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ),
                                                if (projectDesc.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      projectDesc,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        height: 1.4,
                                                        color: Colors
                                                            .grey
                                                            .shade800,
                                                      ),
                                                    ),
                                                  ),
                                                if (projectSkills.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      'Skills: $projectSkills',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTitle(String title) {
    // Different colors for different sections
    Color titleColor;
    switch (title) {
      case 'PERSONAL INFORMATION':
        titleColor = Colors.blue.shade700;
        break;
      case 'CURRICULUM VITAE':
        titleColor = Colors.teal.shade700;
        break;
      case 'PROFESSIONAL SUMMARY':
        titleColor = Colors.purple.shade700;
        break;
      case 'CORE SKILLS':
        titleColor = Colors.orange.shade700;
        break;
      case 'EDUCATION':
        titleColor = Colors.green.shade700;
        break;
      case 'ACHIEVEMENTS':
        titleColor = Colors.red.shade700;
        break;
      case 'TECHNICAL SKILLS':
        titleColor = Colors.indigo.shade700;
        break;
      case 'PERSONAL DETAILS':
        titleColor = Colors.brown.shade700;
        break;
      default:
        titleColor = Colors.grey.shade900;
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: titleColor, width: 2)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: titleColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMainTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatYear(String date) {
    if (date.isEmpty) return '';
    final yearMatch = RegExp(r'\d{4}').firstMatch(date);
    return yearMatch?.group(0) ?? date;
  }

  Future<void> _handleSave(BuildContext context) async {
    try {
      final personalInfo = aiGeneratedData['personalInfo'] as Map? ?? {};
      final name = personalInfo['name']?.toString() ?? 'Smart Assist Resume';

      final resume = SavedResume(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$name Resume',
        template: 'Smart Assist',
        data: aiGeneratedData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ResumeStorageService.instance.saveOrUpdate(resume);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare(BuildContext context, String platform) async {
    try {
      final personalInfo = aiGeneratedData['personalInfo'] as Map? ?? {};
      final name = personalInfo['name']?.toString() ?? 'Smart Assist Resume';

      final resume = SavedResume(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: '$name Resume',
        template: 'Smart Assist',
        data: aiGeneratedData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final shareService = ShareExportService(context);

      switch (platform) {
        case 'email':
          await shareService.shareViaEmail(resume);
          break;
        case 'whatsapp':
          await shareService.shareViaWhatsApp(resume);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
