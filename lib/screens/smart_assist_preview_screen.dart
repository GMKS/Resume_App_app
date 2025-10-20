import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class SmartAssistPreviewScreen extends StatelessWidget {
  final SmartAssistResult result;

  const SmartAssistPreviewScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Assist Preview'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: (choice) async {
              if (choice == 'PDF') {
                await _exportPdf();
              } else if (choice == 'DOCX') {
                await _exportDocx();
              } else if (choice == 'TXT') {
                await _exportTxt();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'PDF',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Export as PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'DOCX',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Export as DOCX'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'TXT',
                child: ListTile(
                  leading: Icon(Icons.text_snippet),
                  title: Text('Export as TXT'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EDF5)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Text(
                    result.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4F8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.role,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4A90A4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.email ?? ''} | ${result.phone ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Summary Section
                  if (result.suggestedSummary.isNotEmpty) ...[
                    _buildSection(
                      'PROFESSIONAL SUMMARY',
                      result.suggestedSummary,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Core Skills Section
                  if (result.coreSkills.isNotEmpty) ...[
                    _buildSection('CORE SKILLS', result.coreSkills.join(' • ')),
                    const SizedBox(height: 24),
                  ],

                  // Enhanced Bullets (Experience)
                  if (result.enhancedBullets.isNotEmpty) ...[
                    _buildSectionTitle('ENHANCED EXPERIENCE'),
                    const SizedBox(height: 16),
                    ...result.enhancedBullets.map(
                      (bullet) => _buildBulletPoint(bullet),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Raw Sections
                  ...result.sectionsRaw.entries.map((entry) {
                    if (entry.value.isNotEmpty) {
                      return Column(
                        children: [
                          _buildSection(entry.key.toUpperCase(), entry.value),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Suggested Keywords
                  if (result.suggestedKeywords.isNotEmpty) ...[
                    _buildSection(
                      'SUGGESTED KEYWORDS',
                      result.suggestedKeywords.join(', '),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ATS Terms
                  if (result.atsTerms.isNotEmpty) ...[
                    _buildSection(
                      'ATS OPTIMIZATION TERMS',
                      result.atsTerms.join(', '),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Alerts/Suggestions
                  if (result.alerts.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMPROVEMENT SUGGESTIONS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...result.alerts.map(
                            (alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $alert',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E4F8A), width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E4F8A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String bullet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1E4F8A),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              bullet,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final file = await exportSmartAssistStyledPdfFromResult(result);
      // Show success message or handle file
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _exportDocx() async {
    try {
      final file = await exportSmartAssistDocxFromResult(result);
      // Show success message or handle file
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _exportTxt() async {
    try {
      final file = await exportSmartAssistTxtFromResult(result);
      // Show success message or handle file
    } catch (e) {
      // Handle error
    }
  }
}
