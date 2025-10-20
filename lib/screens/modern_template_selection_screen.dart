import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/saved_resume.dart';
import '../services/colorful_modern_pdf_exporter.dart';
import '../widgets/colorful_modern_resume_preview.dart';

class ModernTemplateSelectionScreen extends StatefulWidget {
  final SavedResume resume;

  const ModernTemplateSelectionScreen({super.key, required this.resume});

  @override
  State<ModernTemplateSelectionScreen> createState() =>
      _ModernTemplateSelectionScreenState();
}

class _ModernTemplateSelectionScreenState
    extends State<ModernTemplateSelectionScreen> {
  String? selectedTemplate;

  // Modern Color Themes
  final List<ModernTemplateTheme> templates = [
    ModernTemplateTheme(
      id: 'ocean_blue',
      name: 'Ocean Blue',
      description: 'Professional blue tones',
      primaryColor: '#1E40AF', // Deep blue
      secondaryColor: '#3B82F6', // Medium blue
      accentColor: '#60A5FA', // Light blue
      backgroundColor: '#F8FAFC', // Very light blue
      textColor: '#1E293B', // Dark text
      icon: Icons.waves,
    ),
    ModernTemplateTheme(
      id: 'emerald_professional',
      name: 'Emerald Professional',
      description: 'Sophisticated green palette',
      primaryColor: '#059669', // Emerald green
      secondaryColor: '#10B981', // Green
      accentColor: '#34D399', // Light green
      backgroundColor: '#F0FDF4', // Very light green
      textColor: '#064E3B', // Dark green
      icon: Icons.business_center,
    ),
    ModernTemplateTheme(
      id: 'sunset_orange',
      name: 'Sunset Orange',
      description: 'Warm and energetic',
      primaryColor: '#EA580C', // Deep orange
      secondaryColor: '#F97316', // Orange
      accentColor: '#FB923C', // Light orange
      backgroundColor: '#FFF7ED', // Very light orange
      textColor: '#9A3412', // Dark orange
      icon: Icons.wb_sunny,
    ),
    ModernTemplateTheme(
      id: 'royal_purple',
      name: 'Royal Purple',
      description: 'Creative and bold',
      primaryColor: '#7C3AED', // Deep purple
      secondaryColor: '#8B5CF6', // Purple
      accentColor: '#A78BFA', // Light purple
      backgroundColor: '#FAF5FF', // Very light purple
      textColor: '#581C87', // Dark purple
      icon: Icons.diamond,
    ),
    ModernTemplateTheme(
      id: 'midnight_navy',
      name: 'Midnight Navy',
      description: 'Executive dark blue',
      primaryColor: '#1E3A8A', // Navy blue
      secondaryColor: '#1E40AF', // Blue
      accentColor: '#3B82F6', // Light blue
      backgroundColor: '#F1F5F9', // Light gray
      textColor: '#0F172A', // Very dark
      icon: Icons.nightlight_round,
    ),
    ModernTemplateTheme(
      id: 'cherry_red',
      name: 'Cherry Red',
      description: 'Bold and confident',
      primaryColor: '#DC2626', // Deep red
      secondaryColor: '#EF4444', // Red
      accentColor: '#F87171', // Light red
      backgroundColor: '#FEF2F2', // Very light red
      textColor: '#7F1D1D', // Dark red
      icon: Icons.favorite,
    ),
    ModernTemplateTheme(
      id: 'teal_modern',
      name: 'Teal Modern',
      description: 'Fresh and contemporary',
      primaryColor: '#0D9488', // Deep teal
      secondaryColor: '#14B8A6', // Teal
      accentColor: '#5EEAD4', // Light teal
      backgroundColor: '#F0FDFA', // Very light teal
      textColor: '#134E4A', // Dark teal
      icon: Icons.water_drop,
    ),
    ModernTemplateTheme(
      id: 'golden_amber',
      name: 'Golden Amber',
      description: 'Warm and professional',
      primaryColor: '#D97706', // Deep amber
      secondaryColor: '#F59E0B', // Amber
      accentColor: '#FCD34D', // Light amber
      backgroundColor: '#FFFBEB', // Very light amber
      textColor: '#92400E', // Dark amber
      icon: Icons.star,
    ),
    ModernTemplateTheme(
      id: 'slate_gray',
      name: 'Slate Gray',
      description: 'Neutral and modern',
      primaryColor: '#475569', // Slate
      secondaryColor: '#64748B', // Medium slate
      accentColor: '#94A3B8', // Light slate
      backgroundColor: '#F8FAFC', // Very light gray
      textColor: '#1E293B', // Dark slate
      icon: Icons.architecture,
    ),
    ModernTemplateTheme(
      id: 'coral_pink',
      name: 'Coral Pink',
      description: 'Soft and approachable',
      primaryColor: '#DB2777', // Deep pink
      secondaryColor: '#EC4899', // Pink
      accentColor: '#F472B6', // Light pink
      backgroundColor: '#FDF2F8', // Very light pink
      textColor: '#831843', // Dark pink
      icon: Icons.local_florist,
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
                const Icon(Icons.palette, size: 48, color: Colors.purple),
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
                  'Choose from 10 beautiful color combinations for your modern resume',
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
                  childAspectRatio:
                      0.75, // Adjusted from 0.85 to give more height
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = selectedTemplate == template.id;

                  return GestureDetector(
                    onTap: () => setState(() => selectedTemplate = template.id),
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
                              : Colors.grey.shade200,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Color(
                                    int.parse(
                                      '0xFF${template.primaryColor.substring(1)}',
                                    ),
                                  ).withOpacity(0.3)
                                : Colors.black12,
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12), // Reduced from 16
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Added to prevent overflow
                          children: [
                            // Color Preview
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
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
                                      Color(
                                        int.parse(
                                          '0xFF${template.accentColor.substring(1)}',
                                        ),
                                      ),
                                    ],
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
                            ),
                            const SizedBox(height: 12),

                            // Template Info
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    onPressed: selectedTemplate != null
                        ? _previewTemplate
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export PDF'),
                    onPressed: selectedTemplate != null ? _exportPdf : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTemplate != null
                          ? Color(
                              int.parse(
                                '0xFF${templates.firstWhere((t) => t.id == selectedTemplate).primaryColor.substring(1)}',
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

  void _previewTemplate() {
    if (selectedTemplate == null) return;

    final theme = templates.firstWhere((t) => t.id == selectedTemplate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${theme.name} Preview'),
            backgroundColor: Color(
              int.parse(theme.primaryColor.substring(1), radix: 16) +
                  0xFF000000,
            ),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: _exportPdf,
              ),
            ],
          ),
          body: ColorfulModernResumePreview(
            resume: widget.resume,
            theme: theme,
          ),
        ),
      ),
    );
  }

  void _exportPdf() async {
    if (selectedTemplate == null) return;

    final theme = templates.firstWhere((t) => t.id == selectedTemplate);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final filePath = await ColorfulModernPdfExporter.exportToPdf(
        widget.resume,
        theme,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${theme.name} PDF exported successfully!'),
            backgroundColor: Color(
              int.parse(theme.primaryColor.substring(1), radix: 16) +
                  0xFF000000,
            ),
          ),
        );

        // Open the PDF
        await OpenFile.open(filePath);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ModernTemplateTheme {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String backgroundColor;
  final String textColor;
  final IconData icon;

  ModernTemplateTheme({
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'accentColor': accentColor,
    'backgroundColor': backgroundColor,
    'textColor': textColor,
  };

  factory ModernTemplateTheme.fromJson(Map<String, dynamic> json) =>
      ModernTemplateTheme(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        primaryColor: json['primaryColor'] ?? '#1E40AF',
        secondaryColor: json['secondaryColor'] ?? '#3B82F6',
        accentColor: json['accentColor'] ?? '#60A5FA',
        backgroundColor: json['backgroundColor'] ?? '#F8FAFC',
        textColor: json['textColor'] ?? '#1E293B',
        icon: Icons.business_center, // Default icon
      );
}
