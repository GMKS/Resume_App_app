import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/share_export_service.dart';
import 'minimal_resume_preview_screen.dart';

class MinimalTemplateSelectionScreen extends StatefulWidget {
  final SavedResume resume;

  const MinimalTemplateSelectionScreen({super.key, required this.resume});

  @override
  State<MinimalTemplateSelectionScreen> createState() =>
      _MinimalTemplateSelectionScreenState();
}

class _MinimalTemplateSelectionScreenState
    extends State<MinimalTemplateSelectionScreen> {
  String? selectedTemplate;

  // Professional Template based on Megan Clark design
  final List<MinimalTemplateTheme> templates = [
    const MinimalTemplateTheme(
      id: 'professional_green',
      name: 'Professional Green',
      description: 'Modern professional design with green header',
      primaryColor: '#7BA05B', // Green from the header
      secondaryColor: '#6B8E4A', // Darker green
      accentColor: '#8FB96A', // Lighter green
      backgroundColor: '#FFFFFF', // White background
      textColor: '#333333', // Dark text
      icon: Icons.business_center,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Choose Color Theme'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.palette, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  'Select Your Perfect Color Theme',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from 10 beautiful color combinations for your minimal resume',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Templates Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = selectedTemplate == template.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTemplate = template.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(
                                  int.parse(
                                    '0xFF${template.primaryColor.substring(1)}',
                                  ),
                                )
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Color(
                                    int.parse(
                                      '0xFF${template.primaryColor.substring(1)}',
                                    ),
                                  ).withAlpha(77)
                                : Colors.black12,
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Color Preview Section
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Color(
                                    int.parse(
                                      '0xFF${template.primaryColor.substring(1)}',
                                    ),
                                  ),
                                  Color(
                                    int.parse(
                                      '0xFF${template.secondaryColor.substring(1)}',
                                    ),
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                template.icon,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Template Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    template.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),

                                  // Color swatches
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildColorSwatch(template.primaryColor),
                                      _buildColorSwatch(
                                        template.secondaryColor,
                                      ),
                                      _buildColorSwatch(template.accentColor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Selection Indicator
                          if (isSelected)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    '0xFF${template.primaryColor.substring(1)}',
                                  ),
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Selected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedTemplate != null
                        ? () => _previewResume()
                        : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: selectedTemplate != null
                            ? Color(
                                int.parse(
                                  '0xFF${_getSelectedTemplate()!.primaryColor.substring(1)}',
                                ),
                              )
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: selectedTemplate != null
                        ? () => _generateResume()
                        : null,
                    icon: const Icon(Icons.download),
                    label: const Text('Generate PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTemplate != null
                          ? Color(
                              int.parse(
                                '0xFF${_getSelectedTemplate()!.primaryColor.substring(1)}',
                              ),
                            )
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String hexColor) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${hexColor.substring(1)}')),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }

  MinimalTemplateTheme? _getSelectedTemplate() {
    if (selectedTemplate == null) return null;
    return templates.firstWhere(
      (MinimalTemplateTheme template) => template.id == selectedTemplate,
    );
  }

  void _previewResume() {
    if (selectedTemplate == null) return;

    final template = _getSelectedTemplate()!;
    final resumeWithTheme = _applyThemeToResume(template);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MinimalResumePreviewScreen(
          resume: resumeWithTheme,
          theme: template,
        ),
      ),
    );
  }

  void _generateResume() async {
    if (selectedTemplate == null) return;

    try {
      final template = _getSelectedTemplate()!;
      final resumeWithTheme = _applyThemeToResume(template);

      // Check if widget is still mounted before showing dialog
      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Generating your ${template.name} resume...'),
            ],
          ),
        ),
      );

      // Generate PDF with selected theme
      await ShareExportService(context).exportAndOpenPdf(resumeWithTheme);

      // Check if widget is still mounted before closing dialog
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${template.name} resume generated successfully!'),
          backgroundColor: Color(
            int.parse('0xFF${template.primaryColor.substring(1)}'),
          ),
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      // Close loading dialog if open
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  SavedResume _applyThemeToResume(MinimalTemplateTheme theme) {
    final updatedData = Map<String, dynamic>.from(widget.resume.data);

    // Add theme information to resume data
    updatedData['colorTheme'] = {
      'id': theme.id,
      'name': theme.name,
      'primaryColor': theme.primaryColor,
      'secondaryColor': theme.secondaryColor,
      'accentColor': theme.accentColor,
      'backgroundColor': theme.backgroundColor,
      'textColor': theme.textColor,
    };

    return widget.resume.copyWith(
      data: updatedData,
      template: 'Minimal-${theme.id}',
      title: '${widget.resume.title} (${theme.name})',
    );
  }
}

class MinimalTemplateTheme {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String backgroundColor;
  final String textColor;
  final IconData icon;

  const MinimalTemplateTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
