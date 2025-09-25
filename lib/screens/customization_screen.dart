import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/branding.dart';
import '../widgets/branding_customizer.dart';

class CustomizationScreen extends StatefulWidget {
  final String? resumeId;
  final String? templateType;

  const CustomizationScreen({super.key, this.resumeId, this.templateType});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  BrandingTheme _currentTheme = const BrandingTheme();

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    // In a real app, you would load this from SharedPreferences or your database
    // For now, we'll start with the default theme or template-specific theme
    if (widget.templateType != null) {
      switch (widget.templateType!.toLowerCase()) {
        case 'professional':
          _currentTheme = BrandingTheme.professional;
          break;
        case 'creative':
          _currentTheme = BrandingTheme.creative;
          break;
        case 'modern':
          _currentTheme = BrandingTheme.modern;
          break;
        case 'minimal':
          _currentTheme = BrandingTheme.minimalist;
          break;
        case 'classic':
          _currentTheme = BrandingTheme.classic;
          break;
        default:
          _currentTheme = const BrandingTheme();
      }
    }
    setState(() {});
  }

  void _saveTheme() {
    // In a real app, you would save to SharedPreferences or your database
    // For now, we'll just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Branding theme saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Return the theme to the calling screen
    Navigator.pop(context, _currentTheme);
  }

  void _resetToDefault() {
    setState(() {
      _currentTheme = const BrandingTheme();
    });
  }

  void _exportTheme() {
    final themeJson = jsonEncode(_currentTheme.toJson());
    // In a real app, you might save this to a file or share it
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Theme'),
        content: SingleChildScrollView(
          child: SelectableText(
            themeJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importTheme() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Import Theme'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Paste theme JSON here',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final json = jsonDecode(controller.text);
                  final theme = BrandingTheme.fromJson(json);
                  setState(() {
                    _currentTheme = theme;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme imported successfully!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error importing theme: $e')),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Resume Branding'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefault();
                  break;
                case 'export':
                  _exportTheme();
                  break;
                case 'import':
                  _importTheme();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reset to Default'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Theme'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import Theme'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: BrandingCustomizer(
        initialTheme: _currentTheme,
        onThemeChanged: (theme) {
          setState(() {
            _currentTheme = theme;
          });
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveTheme,
                child: const Text('Apply Theme'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
