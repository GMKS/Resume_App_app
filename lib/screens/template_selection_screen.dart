import 'package:flutter/material.dart';
import '../models/resume_template.dart';
import '../models/saved_resume.dart';
import '../services/premium_service.dart';
import 'minimal_resume_preview.dart';
import 'creative_resume_preview.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final SavedResume resumeData;
  final String templateType; // 'minimal' or 'creative'

  const TemplateSelectionScreen({
    super.key,
    required this.resumeData,
    required this.templateType,
  });

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  ResumeTemplate? selectedTemplate;

  List<ResumeTemplate> get templates {
    if (widget.templateType == 'minimal') {
      return ResumeTemplate.getMinimalTemplates();
    } else if (widget.templateType == 'creative') {
      return ResumeTemplate.getCreativeTemplates();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ${widget.templateType.toUpperCase()} Template'),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A365D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Template',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a ${widget.templateType} template that suits your style',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // Template Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = selectedTemplate?.id == template.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTemplate = template;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A365D)
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Template Image
                          Expanded(
                            flex: 4,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: Container(
                                    color: Colors.grey.shade100,
                                    child: Image.asset(
                                      template.imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.description,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),

                                // Premium Badge
                                if (template.isPremium)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Selection Indicator
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A365D),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Template Info
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      template.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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

          // Bottom Action Button
          if (selectedTemplate != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _previewWithSelectedTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A365D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Preview with ${selectedTemplate!.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _previewWithSelectedTemplate() async {
    if (selectedTemplate == null) return;

    // Check if template requires premium
    if (selectedTemplate!.isPremium && !PremiumService.isPremium) {
      PremiumService.showUpgradeDialog(context, 'Template Selection');
      return;
    }

    // Create adapted resume data for the selected template
    final adaptedData = _adaptDataForTemplate(selectedTemplate!);

    // Navigate to appropriate preview screen
    if (!mounted) return;

    if (widget.templateType == 'minimal') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MinimalResumePreview(
            resume: adaptedData,
            templateId: selectedTemplate!.id,
          ),
        ),
      );
    } else if (widget.templateType == 'creative') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreativeResumePreview(
            resume: adaptedData,
            templateId: selectedTemplate!.id,
          ),
        ),
      );
    }
  }

  SavedResume _adaptDataForTemplate(ResumeTemplate template) {
    // Create a copy of the resume data with template-specific adaptations
    final adaptedData = Map<String, dynamic>.from(widget.resumeData.data);

    // Add template information
    adaptedData['selectedTemplateId'] = template.id;
    adaptedData['selectedTemplateName'] = template.name;
    adaptedData['templateCategory'] = template.category;

    // Template-specific data adaptations for colorful/creative templates
    if (widget.templateType == 'creative') {
      // Map minimal template fields to creative template fields
      if (adaptedData['summary'] != null &&
          adaptedData['creativeSummary'] == null) {
        adaptedData['creativeSummary'] = adaptedData['summary'];
      }
      if (adaptedData['name'] != null && adaptedData['full_name'] == null) {
        adaptedData['full_name'] = adaptedData['name'];
      }

      // Apply template-specific color scheme
      final colors = _getTemplateColors(template.id);
      adaptedData['primaryColor'] = colors['primary'];
      adaptedData['accentColor'] = colors['accent'];
      adaptedData['backgroundColor'] = colors['background'];
    }

    return SavedResume(
      id: widget.resumeData.id,
      title: '${widget.resumeData.title} - ${template.name}',
      template: widget.templateType == 'creative'
          ? 'Creative'
          : widget.resumeData.template,
      data: adaptedData,
      createdAt: widget.resumeData.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, String> _getTemplateColors(String templateId) {
    // Define color schemes for different colorful templates
    switch (templateId) {
      case 'minimal_colorful_blue':
        return {
          'primary': '#2196F3',
          'accent': '#1976D2',
          'background': '#E3F2FD',
        };
      case 'minimal_colorful_purple':
        return {
          'primary': '#9C27B0',
          'accent': '#7B1FA2',
          'background': '#F3E5F5',
        };
      case 'minimal_colorful_green':
        return {
          'primary': '#4CAF50',
          'accent': '#388E3C',
          'background': '#E8F5E9',
        };
      case 'minimal_colorful_orange':
        return {
          'primary': '#FF9800',
          'accent': '#F57C00',
          'background': '#FFF3E0',
        };
      default:
        return {
          'primary': '#673AB7',
          'accent': '#512DA8',
          'background': '#EDE7F6',
        };
    }
  }
}
