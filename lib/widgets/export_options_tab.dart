import 'package:flutter/material.dart';
import '../models/customize_settings.dart';
import '../models/custom_resume_data.dart';

class ExportOptionsTab extends StatefulWidget {
  final CustomizeSettings settings;
  final CustomResumeData resumeData;
  final Function(CustomizeSettings) onSettingsChanged;

  const ExportOptionsTab({
    Key? key,
    required this.settings,
    required this.resumeData,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _ExportOptionsTabState createState() => _ExportOptionsTabState();
}

class _ExportOptionsTabState extends State<ExportOptionsTab> {
  bool _isExporting = false;

  Future<void> _exportResume(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // TODO: Implement actual export functionality
      await Future.delayed(const Duration(seconds: 2)); // Simulate export

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume exported as $format successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _shareResume(String platform) async {
    try {
      // TODO: Implement actual sharing functionality
      await Future.delayed(const Duration(seconds: 1)); // Simulate sharing

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume shared via $platform!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export & Share Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred export format and sharing options for your customized resume.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Export Format Section
          _buildExportFormatSection(),
          const SizedBox(height: 24),

          // Language Selection
          _buildLanguageSection(),
          const SizedBox(height: 24),

          // Quick Export Actions
          _buildQuickExportSection(),
          const SizedBox(height: 24),

          // Sharing Options
          _buildSharingSection(),
          const SizedBox(height: 24),

          // Advanced Options
          _buildAdvancedOptionsSection(),
        ],
      ),
    );
  }

  Widget _buildExportFormatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...ExportFormats.values.map((format) {
              IconData icon;
              Color color;
              String description;

              switch (format) {
                case 'PDF':
                  icon = Icons.picture_as_pdf;
                  color = Colors.red;
                  description = 'Best for sharing and printing';
                  break;
                case 'DOCX':
                  icon = Icons.description;
                  color = Colors.blue;
                  description = 'Editable Microsoft Word format';
                  break;
                case 'TXT':
                  icon = Icons.text_snippet;
                  color = Colors.grey;
                  description = 'Plain text for ATS compatibility';
                  break;
                default:
                  icon = Icons.file_present;
                  color = Colors.grey;
                  description = 'Standard format';
              }

              return RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(format),
                  ],
                ),
                subtitle: Text(description),
                value: format,
                groupValue: widget.settings.exportFormat,
                onChanged: (value) {
                  if (value != null) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(exportFormat: value),
                    );
                  }
                },
                activeColor: Colors.indigo,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: widget.settings.language,
                isExpanded: true,
                underline: Container(),
                hint: const Text('Language'),
                items: Languages.values.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(language: value),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Export',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Export PDF',
                  color: Colors.red,
                  onPressed: () => _exportResume('PDF'),
                ),
                _buildExportButton(
                  icon: Icons.description,
                  label: 'Export DOCX',
                  color: Colors.blue,
                  onPressed: () => _exportResume('DOCX'),
                ),
                _buildExportButton(
                  icon: Icons.text_snippet,
                  label: 'Export TXT',
                  color: Colors.grey,
                  onPressed: () => _exportResume('TXT'),
                ),
                _buildExportButton(
                  icon: Icons.preview,
                  label: 'Preview',
                  color: Colors.green,
                  onPressed: () {
                    // TODO: Navigate to preview
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : onPressed,
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildSharingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Resume',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResume('Email'),
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResume('WhatsApp'),
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Include sharing link'),
              subtitle: const Text('Generate a shareable link for your resume'),
              value: widget.settings.shareLink,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(shareLink: value),
                );
              },
              activeColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.settings.shareLink)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'https://resumeapp.com/share/your-resume-id',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.blue.shade700),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard!'),
                          ),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include QR Code'),
              subtitle: const Text(
                'Add QR code linking to your portfolio or contact',
              ),
              value: widget.settings.qrCode,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(qrCode: value),
                );
              },
              activeColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.indigo),
              title: const Text('Auto-save interval'),
              subtitle: const Text(
                'Automatically save changes every 2 minutes',
              ),
              trailing: Switch(
                value: true, // TODO: Connect to actual auto-save setting
                onChanged: (value) {
                  // TODO: Implement auto-save toggle
                },
                activeColor: Colors.indigo,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.indigo),
              title: const Text('Cloud backup'),
              subtitle: const Text('Save your customizations to the cloud'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to cloud backup settings
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
