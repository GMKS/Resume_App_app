import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/branding.dart';

class BrandingCustomizer extends StatefulWidget {
  final BrandingTheme initialTheme;
  final ValueChanged<BrandingTheme> onThemeChanged;

  const BrandingCustomizer({
    super.key,
    required this.initialTheme,
    required this.onThemeChanged,
  });

  @override
  State<BrandingCustomizer> createState() => _BrandingCustomizerState();
}

class _BrandingCustomizerState extends State<BrandingCustomizer> {
  late BrandingTheme _currentTheme;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  void _updateTheme(BrandingTheme newTheme) {
    setState(() {
      _currentTheme = newTheme;
    });
    widget.onThemeChanged(newTheme);
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        final String base64String = base64Encode(bytes);
        _updateTheme(
          _currentTheme.copyWith(logoBase64: base64String, showLogo: true),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Widget _buildColorPicker(
    String label,
    String currentColor,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${currentColor.substring(1)}')),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: currentColor),
                decoration: const InputDecoration(
                  labelText: 'Hex Color',
                  prefixText: '#',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    onChanged('#$value');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontSelector() {
    const fonts = [
      'Roboto',
      'Inter',
      'Montserrat',
      'Georgia',
      'Times New Roman',
      'Arial',
      'Helvetica',
      'Roboto Mono',
      'Open Sans',
      'Lato',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Family',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currentTheme.fontFamily,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: fonts
              .map(
                (font) => DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _updateTheme(_currentTheme.copyWith(fontFamily: value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${value.toStringAsFixed(0)}pt)',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value,
          min: 10,
          max: 28,
          divisions: 18,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLogoPositionSelector() {
    const positions = [
      {'value': 'top-left', 'label': 'Top Left'},
      {'value': 'top-right', 'label': 'Top Right'},
      {'value': 'center', 'label': 'Center'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo Position',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currentTheme.logoPosition,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: positions
              .map(
                (pos) => DropdownMenuItem(
                  value: pos['value'],
                  child: Text(pos['label']!),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _updateTheme(_currentTheme.copyWith(logoPosition: value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildThemePresets() {
    final presets = [
      {'name': 'Professional', 'theme': BrandingTheme.professional},
      {'name': 'Creative', 'theme': BrandingTheme.creative},
      {'name': 'Modern', 'theme': BrandingTheme.modern},
      {'name': 'Minimalist', 'theme': BrandingTheme.minimalist},
      {'name': 'Classic', 'theme': BrandingTheme.classic},
      {'name': 'Tech', 'theme': BrandingTheme.tech},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Themes',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final theme = preset['theme'] as BrandingTheme;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _updateTheme(
                    theme.copyWith(
                      logoBase64: _currentTheme.logoBase64,
                      showLogo: _currentTheme.showLogo,
                      logoPosition: _currentTheme.logoPosition,
                    ),
                  ),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentTheme.primaryColor == theme.primaryColor
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Color(
                                  int.parse(
                                    '0xFF${theme.primaryColor.substring(1)}',
                                  ),
                                ),
                                Color(
                                  int.parse(
                                    '0xFF${theme.secondaryColor.substring(1)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    '0xFF${theme.accentColor.substring(1)}',
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            alignment: Alignment.center,
                            child: Text(
                              preset['name'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: theme.fontFamily,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemePresets(),
          const SizedBox(height: 32),

          const Text(
            'Colors',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildColorPicker('Primary Color', _currentTheme.primaryColor, (
            color,
          ) {
            _updateTheme(_currentTheme.copyWith(primaryColor: color));
          }),
          const SizedBox(height: 16),
          _buildColorPicker('Secondary Color', _currentTheme.secondaryColor, (
            color,
          ) {
            _updateTheme(_currentTheme.copyWith(secondaryColor: color));
          }),
          const SizedBox(height: 16),
          _buildColorPicker('Accent Color', _currentTheme.accentColor, (color) {
            _updateTheme(_currentTheme.copyWith(accentColor: color));
          }),

          const SizedBox(height: 32),
          const Text(
            'Typography',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildFontSelector(),
          const SizedBox(height: 16),
          _buildFontSizeSlider(
            'Header Font Size',
            _currentTheme.headerFontSize,
            (value) {
              _updateTheme(_currentTheme.copyWith(headerFontSize: value));
            },
          ),
          const SizedBox(height: 8),
          _buildFontSizeSlider('Body Font Size', _currentTheme.bodyFontSize, (
            value,
          ) {
            _updateTheme(_currentTheme.copyWith(bodyFontSize: value));
          }),

          const SizedBox(height: 32),
          const Text(
            'Logo',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _currentTheme.showLogo,
                onChanged: (value) {
                  _updateTheme(_currentTheme.copyWith(showLogo: value));
                },
              ),
              const SizedBox(width: 8),
              const Text('Show Logo'),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentTheme.showLogo) ...[
            ElevatedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.image),
              label: Text(
                _currentTheme.logoBase64 != null ? 'Change Logo' : 'Add Logo',
              ),
            ),
            if (_currentTheme.logoBase64 != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.memory(
                  base64Decode(_currentTheme.logoBase64!),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              _buildLogoPositionSelector(),
            ],
          ],

          const SizedBox(height: 32),
          const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentTheme.showLogo && _currentTheme.logoBase64 != null)
                  Align(
                    alignment: _currentTheme.logoPosition == 'top-left'
                        ? Alignment.centerLeft
                        : _currentTheme.logoPosition == 'center'
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Image.memory(
                        base64Decode(_currentTheme.logoBase64!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: _currentTheme.headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(
                      int.parse(
                        '0xFF${_currentTheme.primaryColor.substring(1)}',
                      ),
                    ),
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Software Engineer',
                  style: TextStyle(
                    fontSize: _currentTheme.bodyFontSize + 1,
                    color: Color(
                      int.parse(
                        '0xFF${_currentTheme.secondaryColor.substring(1)}',
                      ),
                    ),
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a sample resume text to show how your chosen theme will look.',
                  style: TextStyle(
                    fontSize: _currentTheme.bodyFontSize,
                    color: Color(
                      int.parse(
                        '0xFF${_currentTheme.secondaryColor.substring(1)}',
                      ),
                    ),
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        '0xFF${_currentTheme.accentColor.substring(1)}',
                      ),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Accent Element',
                    style: TextStyle(
                      fontSize: _currentTheme.bodyFontSize - 1,
                      color: Colors.white,
                      fontFamily: _currentTheme.fontFamily,
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
}

// Color picker widget for more advanced color selection
class ColorPickerDialog extends StatefulWidget {
  final String initialColor;
  final ValueChanged<String> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final commonColors = [
      '#2196F3',
      '#4CAF50',
      '#FF9800',
      '#F44336',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#009688',
      '#8BC34A',
      '#CDDC39',
      '#FFC107',
      '#FF5722',
      '#795548',
      '#607D8B',
      '#000000',
      '#424242',
      '#757575',
      '#BDBDBD',
      '#E0E0E0',
      '#FFFFFF',
    ];

    return AlertDialog(
      title: const Text('Choose Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: commonColors.length,
            itemBuilder: (context, index) {
              final color = commonColors[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${color.substring(1)}')),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.black
                          : Colors.grey.shade300,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: _selectedColor),
            decoration: const InputDecoration(
              labelText: 'Custom Hex Color',
              prefixText: '#',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.length == 6) {
                setState(() => _selectedColor = '#$value');
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorChanged(_selectedColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
