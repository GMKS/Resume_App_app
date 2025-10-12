import 'package:flutter/material.dart';
import '../models/customize_settings.dart';
import '../models/custom_resume_data.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../widgets/design_settings_tab.dart';
import '../widgets/content_sections_tab.dart';
import '../widgets/smart_features_tab.dart';
import '../widgets/export_options_tab.dart';
import 'custom_resume_preview.dart';

class CustomizeScreen extends StatefulWidget {
  final CustomizeSettings? initialSettings;
  final CustomResumeData? initialResumeData;
  final SavedResume? originalResume;

  const CustomizeScreen({
    super.key,
    this.initialSettings,
    this.initialResumeData,
    this.originalResume,
  });

  @override
  _CustomizeScreenState createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CustomizeSettings _settings;
  late CustomResumeData _resumeData;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _settings = widget.initialSettings ?? const CustomizeSettings();
    _resumeData = widget.initialResumeData ?? const CustomResumeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSettingsChanged(CustomizeSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasUnsavedChanges = true;
    });
  }

  void _onResumeDataChanged(CustomResumeData newResumeData) {
    setState(() {
      _resumeData = newResumeData;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    try {
      if (widget.originalResume != null) {
        // Create an updated SavedResume with customizations applied
        final updatedResume = _applyCustomizationsToResume(
          widget.originalResume!,
          _settings,
          _resumeData,
        );

        // Save the updated resume using ResumeStorageService
        await ResumeStorageService.instance.saveOrUpdate(updatedResume);

        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume customizations saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to show the updated resume
        if (context.mounted) {
          Navigator.of(
            context,
          ).pop(true); // Return true to indicate changes were saved
        }
      } else {
        // Fallback for cases where there's no original resume
        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customizations applied locally!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Apply customization settings to the original SavedResume
  SavedResume _applyCustomizationsToResume(
    SavedResume originalResume,
    CustomizeSettings settings,
    CustomResumeData resumeData,
  ) {
    // Create a copy of the original resume data
    final updatedData = Map<String, dynamic>.from(originalResume.data);

    // Apply design customizations to the data
    updatedData['customizations'] = {
      'templateStyle': settings.templateStyle,
      'colorTheme': settings.colorTheme,
      'fontFamily': settings.fontFamily,
      'fontSize': settings.fontSize,
      'lineSpacing': settings.lineSpacing,
      'sectionSpacing': settings.sectionSpacing,
      'backgroundStyle': settings.backgroundStyle,
    };

    // Apply branding theme if it exists
    if (settings.colorTheme.isNotEmpty) {
      final brandingTheme = _getBrandingThemeFromSettings(settings);
      updatedData['brandingTheme'] = brandingTheme;
    }

    // Update content if resumeData has changes
    if (resumeData.fullName.isNotEmpty) {
      if (updatedData['personalInfo'] == null) {
        updatedData['personalInfo'] = <String, dynamic>{};
      }
      final personalInfo = updatedData['personalInfo'] as Map<String, dynamic>;
      personalInfo['fullName'] = resumeData.fullName;
      personalInfo['name'] = resumeData.fullName;
      personalInfo['jobTitle'] = resumeData.jobTitle;
      personalInfo['title'] = resumeData.jobTitle;
      personalInfo['email'] = resumeData.contactInfo.email;
      personalInfo['phone'] = resumeData.contactInfo.phone;
      personalInfo['linkedin'] = resumeData.contactInfo.linkedin;
      personalInfo['portfolio'] = resumeData.contactInfo.website;
      personalInfo['location'] = resumeData.contactInfo.location;
    }

    if (resumeData.summary.isNotEmpty) {
      updatedData['summary'] = resumeData.summary;
    }

    // Return updated resume
    return SavedResume(
      id: originalResume.id,
      title: originalResume.title,
      template: originalResume.template,
      data: updatedData,
      createdAt: originalResume.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert CustomizeSettings to a branding theme map
  Map<String, dynamic> _getBrandingThemeFromSettings(
    CustomizeSettings settings,
  ) {
    // Define color mappings for different themes
    final colorMappings = {
      'Professional Blue': {
        'primaryColor': '#1A365D',
        'accentColor': '#2B6CB0',
      },
      'Elegant Black': {'primaryColor': '#1A202C', 'accentColor': '#4A5568'},
      'Creative Green': {'primaryColor': '#276749', 'accentColor': '#38A169'},
      'Modern Purple': {'primaryColor': '#553C9A', 'accentColor': '#7C3AED'},
      'Classic Navy': {'primaryColor': '#2A4A6B', 'accentColor': '#3182CE'},
    };

    final colors =
        colorMappings[settings.colorTheme] ??
        colorMappings['Professional Blue']!;

    return {
      'primaryColor': colors['primaryColor'],
      'accentColor': colors['accentColor'],
      'fontFamily': settings.fontFamily,
    };
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all customizations to default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _settings = const CustomizeSettings();
        _resumeData = const CustomResumeData();
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _previewResume() async {
    // Navigate to preview screen with current settings and data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomResumePreview(settings: _settings, resumeData: _resumeData),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              await _saveChanges();
              Navigator.of(context).pop(true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize Resume'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.palette), text: 'Design'),
              Tab(icon: Icon(Icons.edit_document), text: 'Content'),
              Tab(icon: Icon(Icons.smart_toy), text: 'Smart Features'),
              Tab(icon: Icon(Icons.file_download), text: 'Export'),
            ],
          ),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveChanges,
                tooltip: 'Save Changes',
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'save':
                    await _saveChanges();
                    break;
                  case 'reset':
                    await _resetToDefaults();
                    break;
                  case 'preview':
                    await _previewResume();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: ListTile(
                    leading: Icon(Icons.save),
                    title: Text('Save Changes'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'preview',
                  child: ListTile(
                    leading: Icon(Icons.preview),
                    title: Text('Preview Resume'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Colors.red),
                    title: Text(
                      'Reset to Defaults',
                      style: TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DesignSettingsTab(
              settings: _settings,
              onSettingsChanged: _onSettingsChanged,
            ),
            ContentSectionsTab(
              resumeData: _resumeData,
              onResumeDataChanged: _onResumeDataChanged,
            ),
            SmartFeaturesTab(
              settings: _settings,
              resumeData: _resumeData,
              onSettingsChanged: _onSettingsChanged,
              onResumeDataChanged: _onResumeDataChanged,
            ),
            ExportOptionsTab(
              settings: _settings,
              resumeData: _resumeData,
              onSettingsChanged: _onSettingsChanged,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _previewResume,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.preview),
          label: const Text('Preview'),
        ),
        bottomNavigationBar: _hasUnsavedChanges
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have unsaved changes',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Now'),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
