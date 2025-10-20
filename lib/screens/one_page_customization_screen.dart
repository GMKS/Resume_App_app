import 'package:flutter/material.dart';
import '../models/saved_resume.dart';

class OnePageCustomizationScreen extends StatefulWidget {
  final SavedResume resume;
  final Function(Map<String, String>) onCustomizationChanged;

  const OnePageCustomizationScreen({
    super.key,
    required this.resume,
    required this.onCustomizationChanged,
  });

  @override
  State<OnePageCustomizationScreen> createState() =>
      _OnePageCustomizationScreenState();
}

class _OnePageCustomizationScreenState
    extends State<OnePageCustomizationScreen> {
  Color _accentColor = const Color(0xFF1976D2);
  String _selectedFont = 'Default';
  String _layoutStyle = 'Two Column';
  String _templateVariant = 'One Page';

  final List<Color> _colorOptions = [
    const Color(0xFF1976D2), // Blue
    const Color(0xFF388E3C), // Green
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFFD32F2F), // Red
    const Color(0xFFF57C00), // Orange
    const Color(0xFF1976D2), // Navy
    const Color(0xFF424242), // Dark Grey
    const Color(0xFF795548), // Brown
  ];

  final List<String> _fontOptions = [
    'Default',
    'Professional',
    'Modern',
    'Classic',
    'Creative',
  ];

  final List<String> _layoutOptions = [
    'Two Column',
    'Traditional',
    'Modern Stack',
    'Compact',
  ];

  final List<Map<String, String>> _templateOptions = const [
    {
      'key': 'One Page',
      'label': 'One Page',
      'desc': 'Clean two-column layout with sidebar',
    },
    {
      'key': 'Classic',
      'label': 'Classic',
      'desc': 'Traditional, ATS-friendly structure',
    },
    {
      'key': 'Modern',
      'label': 'Modern',
      'desc': 'Bold headings, strong hierarchy',
    },
    {
      'key': 'Minimal',
      'label': 'Minimal',
      'desc': 'Airy spacing, simple typography',
    },
    {
      'key': 'Professional',
      'label': 'Professional',
      'desc': 'Balanced corporate styling',
    },
    {
      'key': 'Creative',
      'label': 'Creative',
      'desc': 'Color-forward with visual accents',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load existing customization from resume data
    final data = widget.resume.data;
    if (data['accentColor'] != null) {
      try {
        _accentColor = Color(int.parse(data['accentColor']!));
      } catch (e) {
        _accentColor = const Color(0xFF1976D2);
      }
    }

    // Ensure font value exists in options
    String savedFont = data['fontStyle'] ?? 'Default';
    if (_fontOptions.contains(savedFont)) {
      _selectedFont = savedFont;
    } else {
      _selectedFont = 'Default';
    }

    // Ensure layout value exists in options
    String savedLayout = data['layoutStyle'] ?? 'Two Column';
    if (_layoutOptions.contains(savedLayout)) {
      _layoutStyle = savedLayout;
    } else {
      _layoutStyle = 'Two Column';
    }

    // Template variant
    final savedTemplate = data['templateVariant'] ?? 'One Page';
    final hasTemplate = _templateOptions.any((t) => t['key'] == savedTemplate);
    _templateVariant = hasTemplate ? savedTemplate : 'One Page';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize One Page Resume'),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveCustomization,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorSection(),
            const SizedBox(height: 24),
            _buildFontSection(),
            const SizedBox(height: 24),
            _buildTemplateGallerySection(),
            const SizedBox(height: 24),
            _buildLayoutSection(),
            const SizedBox(height: 24),
            _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGallerySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Gallery',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _templateOptions.map((tpl) {
                final selected = _templateVariant == tpl['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _templateVariant = tpl['key']!;
                      // Set sensible defaults when switching templates
                      switch (_templateVariant) {
                        case 'Classic':
                          _layoutStyle = 'Traditional';
                          _selectedFont = _fontOptions.contains('Classic')
                              ? 'Classic'
                              : 'Default';
                          break;
                        case 'Modern':
                          _layoutStyle = 'Modern Stack';
                          _selectedFont = _fontOptions.contains('Modern')
                              ? 'Modern'
                              : 'Default';
                          break;
                        case 'Minimal':
                          _layoutStyle = 'Compact';
                          _selectedFont = 'Default';
                          break;
                        case 'Professional':
                          _layoutStyle = 'Two Column';
                          _selectedFont = _fontOptions.contains('Professional')
                              ? 'Professional'
                              : 'Default';
                          break;
                        case 'Creative':
                          _layoutStyle = 'Modern Stack';
                          _selectedFont = _fontOptions.contains('Creative')
                              ? 'Creative'
                              : 'Default';
                          break;
                        default:
                          _layoutStyle = 'Two Column';
                          _selectedFont = 'Default';
                      }
                    });
                  },
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _accentColor : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      color: selected
                          ? _accentColor.withOpacity(0.04)
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.article,
                              color: selected ? _accentColor : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tpl['label']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? _accentColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tpl['desc']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accent Color',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _accentColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _accentColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Style',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedFont,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _fontOptions.map((font) {
                return DropdownMenuItem(value: font, child: Text(font));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFont = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layout Style',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: _layoutOptions.map((layout) {
                return RadioListTile<String>(
                  title: Text(layout),
                  value: layout,
                  groupValue: _layoutStyle,
                  activeColor: _accentColor,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _layoutStyle = value;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header with accent color
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Your Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Preview content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Title',
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Font: $_selectedFont',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Layout: $_layoutStyle',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sample section with accent color',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCustomization() {
    final customizationData = {
      'accentColor': _accentColor.value.toString(),
      'fontStyle': _selectedFont,
      'layoutStyle': _layoutStyle,
      'templateVariant': _templateVariant,
    };

    widget.onCustomizationChanged(customizationData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customization saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }
}
