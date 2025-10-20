import 'package:flutter/material.dart';
import '../models/customize_settings.dart';

class DesignSettingsTab extends StatefulWidget {
  final CustomizeSettings settings;
  final Function(CustomizeSettings) onSettingsChanged;

  const DesignSettingsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<DesignSettingsTab> createState() => _DesignSettingsTabState();
}

class _DesignSettingsTabState extends State<DesignSettingsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Template Style'),
          _buildTemplateStylePicker(),
          const SizedBox(height: 24),
          _buildSectionHeader('Layout'),
          _buildLayoutTypePicker(),
          const SizedBox(height: 24),
          _buildSectionHeader('Color Theme'),
          _buildColorThemePicker(),
          const SizedBox(height: 24),
          _buildAdvancedColorOptions(),
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
              children: ['Modern', 'Minimalist', 'Creative', 'ATS-Friendly']
                  .map((style) {
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
                      selectedColor: Colors.indigo.withValues(alpha: 0.2),
                      checkmarkColor: Colors.indigo,
                    );
                  })
                  .toList(),
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
            ...['Single Column', 'Two Column', 'Grid'].map((layout) {
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
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
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
              itemCount: _getColorThemes().length,
              itemBuilder: (context, index) {
                final theme = _getColorThemes().entries.elementAt(index);
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
                        style: const TextStyle(
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

  Map<String, String> _getColorThemes() {
    return {
      'Blue': '#3F51B5',
      'Red': '#F44336',
      'Green': '#4CAF50',
      'Purple': '#9C27B0',
      'Orange': '#FF9800',
      'Teal': '#009688',
    };
  }

  Widget _buildAdvancedColorOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Color Options',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildColorInput(
              'Primary Color (hex)',
              widget.settings.colorTheme,
              (value) {
                widget.onSettingsChanged(
                  widget.settings.copyWith(colorTheme: value),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildColorInput('Accent Color (hex)', '#2B6CB0', (value) {
              // Handle accent color change
            }),
            const SizedBox(height: 16),
            _buildFontFamilySelector(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply Theme'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorInput(
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            initialValue: currentValue,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Family',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: widget.settings.fontFamily,
            isExpanded: true,
            underline: const SizedBox(),
            items:
                ['Roboto', 'Arial', 'Georgia', 'Times New Roman', 'Helvetica']
                    .map(
                      (font) => DropdownMenuItem(
                        value: font,
                        child: Text(font, style: TextStyle(fontFamily: font)),
                      ),
                    )
                    .toList(),
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
    );
  }
}
