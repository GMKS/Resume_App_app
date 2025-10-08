import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/customize_settings.dart';

class DesignSettingsTab extends StatefulWidget {
  final CustomizeSettings settings;
  final Function(CustomizeSettings) onSettingsChanged;

  const DesignSettingsTab({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _DesignSettingsTabState createState() => _DesignSettingsTabState();
}

class _DesignSettingsTabState extends State<DesignSettingsTab> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onSettingsChanged(
          widget.settings.copyWith(profilePhotoPath: image.path),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCustomLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 90,
      );

      if (image != null) {
        widget.onSettingsChanged(
          widget.settings.copyWith(customLogoPath: image.path),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeProfilePhoto() {
    widget.onSettingsChanged(widget.settings.copyWith(profilePhotoPath: ''));
  }

  void _removeCustomLogo() {
    widget.onSettingsChanged(widget.settings.copyWith(customLogoPath: ''));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Style Section
          _buildSectionHeader('Template Style'),
          _buildTemplateStylePicker(),
          const SizedBox(height: 24),

          // Layout Section
          _buildSectionHeader('Layout'),
          _buildLayoutTypePicker(),
          const SizedBox(height: 24),

          // Color Theme Section
          _buildSectionHeader('Color Theme'),
          _buildColorThemePicker(),
          const SizedBox(height: 24),

          // Typography Section
          _buildSectionHeader('Typography'),
          _buildFontFamilyPicker(),
          _buildFontSizeSlider(),
          const SizedBox(height: 24),

          // Spacing Section
          _buildSectionHeader('Spacing'),
          _buildLineSpacingSlider(),
          _buildSectionSpacingSlider(),
          const SizedBox(height: 24),

          // Background Section
          _buildSectionHeader('Background'),
          _buildBackgroundStylePicker(),
          const SizedBox(height: 24),

          // Photos Section
          _buildSectionHeader('Photos & Images'),
          _buildProfilePhotoSection(),
          const SizedBox(height: 16),
          _buildCustomLogoSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildTemplateStylePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a template style',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemplateStyles.values.map((style) {
                final isSelected = widget.settings.templateStyle == style;
                return FilterChip(
                  label: Text(style),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onSettingsChanged(
                        widget.settings.copyWith(templateStyle: style),
                      );
                    }
                  },
                  selectedColor: Colors.indigo.shade100,
                  checkmarkColor: Colors.indigo,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutTypePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Layout Type',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...LayoutTypes.values.map((layout) {
              return RadioListTile<String>(
                title: Text(layout),
                value: layout,
                groupValue: widget.settings.layoutType,
                onChanged: (value) {
                  if (value != null) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(layoutType: value),
                    );
                  }
                },
                activeColor: Colors.indigo,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorThemePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Theme',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3,
              ),
              itemCount: ColorThemes.themes.length,
              itemBuilder: (context, index) {
                final theme = ColorThemes.themes.entries.elementAt(index);
                final isSelected = widget.settings.colorTheme == theme.value;

                return GestureDetector(
                  onTap: () {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(colorTheme: theme.value),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.indigo
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color: Color(
                        int.parse(theme.value.replaceFirst('#', '0xFF')),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        theme.key,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontFamilyPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Font Family',
              style: TextStyle(fontWeight: FontWeight.w500),
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
                value: widget.settings.fontFamily,
                isExpanded: true,
                underline: Container(),
                hint: const Text('Font Family'),
                items: FontFamilies.values.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(font, style: TextStyle(fontFamily: font)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(fontFamily: value),
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

  Widget _buildFontSizeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Size: ${widget.settings.fontSize.toInt()}pt',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: widget.settings.fontSize,
              min: 8.0,
              max: 18.0,
              divisions: 10,
              activeColor: Colors.indigo,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(fontSize: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineSpacingSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Line Spacing: ${widget.settings.lineSpacing.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: widget.settings.lineSpacing,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              activeColor: Colors.indigo,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(lineSpacing: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSpacingSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section Spacing: ${widget.settings.sectionSpacing.toInt()}pt',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: widget.settings.sectionSpacing,
              min: 8.0,
              max: 32.0,
              divisions: 12,
              activeColor: Colors.indigo,
              onChanged: (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(sectionSpacing: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStylePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Style',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...BackgroundStyles.values.map((style) {
              return RadioListTile<String>(
                title: Text(style),
                value: style,
                groupValue: widget.settings.backgroundStyle,
                onChanged: (value) {
                  if (value != null) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(backgroundStyle: value),
                    );
                  }
                },
                activeColor: Colors.indigo,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (widget.settings.profilePhotoPath?.isNotEmpty == true) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: FileImage(
                      File(widget.settings.profilePhotoPath!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Photo selected'),
                        Text(
                          widget.settings.profilePhotoPath!.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeProfilePhoto,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _pickProfilePhoto,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                widget.settings.profilePhotoPath?.isEmpty != false
                    ? 'Add Profile Photo'
                    : 'Change Photo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLogoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Logo',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (widget.settings.customLogoPath?.isNotEmpty == true) ...[
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.settings.customLogoPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Logo selected'),
                        Text(
                          widget.settings.customLogoPath!.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeCustomLogo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _pickCustomLogo,
              icon: const Icon(Icons.business),
              label: Text(
                widget.settings.customLogoPath?.isEmpty != false
                    ? 'Add Custom Logo'
                    : 'Change Logo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
