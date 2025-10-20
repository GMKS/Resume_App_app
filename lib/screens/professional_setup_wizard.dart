import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../models/branding.dart';
import '../services/resume_storage_service.dart';
import 'professional_resume_form_screen.dart';
import 'professional_resume_preview.dart';

class ProfessionalSetupWizard extends StatefulWidget {
  final String title;
  const ProfessionalSetupWizard({super.key, required this.title});

  @override
  State<ProfessionalSetupWizard> createState() =>
      _ProfessionalSetupWizardState();
}

class _ProfessionalSetupWizardState extends State<ProfessionalSetupWizard> {
  // Theme & palettes
  BrandingTheme _theme = BrandingTheme.professional;
  bool _hasUnsavedChanges = false;
  final List<BrandingTheme> _palettes = const [
    BrandingTheme.professional,
    BrandingTheme.creative,
    BrandingTheme.modern,
    BrandingTheme.minimalist,
    BrandingTheme.classic,
    BrandingTheme.tech,
  ];

  // Template variants
  final List<String> _templateVariants = const [
    'Classic Professional',
    'Modern Executive',
    'Creative Professional',
    'Minimal Professional',
  ];
  String _selectedTemplate = 'Classic Professional';

  // Layouts
  final List<String> _layouts = const [
    'Single Column',
    'Two Columns',
    'Sidebar',
    'Grid Based',
    'Card Based',
    'Tabbed',
  ];
  String _selectedLayout = 'Single Column';

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  // Actions
  Future<void> _onPreview() async {
    try {
      // Create temporary resume for preview
      final tempResume = SavedResume(
        id: 'temp_preview',
        title: widget.title,
        template: 'Professional',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: {'branding': _theme.toJson(), 'layout': _selectedLayout},
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalResumePreview(resume: tempResume),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
      }
    }
  }

  void _onDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download available from editor export.')),
    );
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text('This will discard your selections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  Future<void> _onDone() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create a minimal SavedResume locally and navigate to the editor
      final resume = SavedResume(
        id: ResumeStorageService.instance.generateId(),
        title: widget.title,
        template: 'Professional',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: {
          'branding': _theme.toJson(),
          'layout': _selectedLayout,
          'templateVariant': _selectedTemplate,
        },
      );

      // Save locally first for immediate response
      await ResumeStorageService.instance.saveOrUpdate(resume);

      // Dismiss loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to editor
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalResumeFormScreen(existing: resume),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog on error
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving resume: $e')));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Changes?'),
        content: const Text(
          'You have unsaved changes. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'exit'),
            child: const Text('Exit Without Saving'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Continue Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'save':
        await _onDone();
        return false; // Navigation handled by _onDone
      case 'exit':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Professional Setup'),
          actions: [
            IconButton(
              onPressed: _onPreview,
              icon: const Icon(Icons.remove_red_eye_outlined),
            ),
            IconButton(
              onPressed: _onDownload,
              icon: const Icon(Icons.download_outlined),
            ),
            IconButton(
              onPressed: _onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Template Variant Selection
              const Text(
                'Choose Template Style',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _templateVariants.length,
                itemBuilder: (context, index) {
                  final template = _templateVariants[index];
                  final selected = template == _selectedTemplate;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTemplate = template);
                      _markChanged();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade100,
                              ),
                              child: _getTemplatePreview(template),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              template,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Theme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _palettes.map((p) {
                  final selected =
                      p.fontFamily == _theme.fontFamily &&
                      p.primaryColor == _theme.primaryColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _theme = p);
                      _markChanged();
                    },
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ColorDotRow(hex: p.primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            p.fontFamily,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Layout Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _layouts.map((l) {
                  final selected = l == _selectedLayout;
                  return ChoiceChip(
                    label: Text(l),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedLayout = l);
                      _markChanged();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Layout Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _LayoutPreviewCard(layout: _selectedLayout),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _onDone,
              child: const Text('Done'),
            ),
          ),
        ),
      ),
    );
  }

  // Template preview generator
  Widget _getTemplatePreview(String template) {
    switch (template) {
      case 'Classic Professional':
        return Column(
          children: [
            Container(
              height: 20,
              width: double.infinity,
              color: Colors.blue.shade200,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            Container(
              height: 16,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Container(
              height: 16,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Container(
              height: 16,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            Container(
              height: 20,
              color: Colors.blue.shade100,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Container(height: 16, color: Colors.grey.shade300),
          ],
        );
      case 'Modern Executive':
        return Row(
          children: [
            Container(
              width: 30,
              color: Colors.blue.shade800,
              margin: const EdgeInsets.only(right: 4),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 18,
                    color: Colors.grey.shade800,
                    margin: const EdgeInsets.only(bottom: 3),
                  ),
                  Container(
                    height: 14,
                    color: Colors.grey.shade400,
                    margin: const EdgeInsets.only(bottom: 3),
                  ),
                  Container(
                    height: 14,
                    color: Colors.grey.shade400,
                    margin: const EdgeInsets.only(bottom: 3),
                  ),
                  Container(height: 16, color: Colors.blue.shade100),
                ],
              ),
            ),
          ],
        );
      case 'Creative Professional':
        return Stack(
          children: [
            Container(color: Colors.black),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(height: 12, color: Colors.white),
            ),
            Positioned(
              top: 24,
              left: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Container(
                    height: 8,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 2),
                  ),
                  Container(
                    height: 8,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 2),
                  ),
                  Container(height: 8, color: Colors.white),
                ],
              ),
            ),
          ],
        );
      case 'Minimal Professional':
        return Column(
          children: [
            Container(
              height: 18,
              color: Colors.grey.shade700,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Container(
              height: 12,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Container(
              height: 12,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Container(
              height: 12,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(height: 10, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Container(height: 10, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Container(height: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        );
      default:
        return Container(color: Colors.grey.shade300);
    }
  }
}

class _ColorDotRow extends StatelessWidget {
  final String hex;
  const _ColorDotRow({required this.hex});

  @override
  Widget build(BuildContext context) {
    Color c = _fromHex(hex);
    return Row(
      children: [
        _dot(c),
        const SizedBox(width: 6),
        _dot(c.withOpacity(0.7)),
        const SizedBox(width: 6),
        _dot(Colors.white),
      ],
    );
  }

  static Widget _dot(Color c) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black12),
    ),
  );

  static Color _fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _LayoutPreviewCard extends StatelessWidget {
  final String layout;
  const _LayoutPreviewCard({required this.layout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _getLayoutPreview(),
    );
  }

  Widget _getLayoutPreview() {
    switch (layout) {
      case 'Single Column':
        return Column(
          children: [
            Container(height: 20, color: Colors.blue.shade200),
            const SizedBox(height: 4),
            Container(height: 16, color: Colors.grey.shade300),
            const SizedBox(height: 4),
            Container(height: 16, color: Colors.grey.shade300),
            const SizedBox(height: 4),
            Container(height: 16, color: Colors.grey.shade300),
          ],
        );
      case 'Two Columns':
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(height: 20, color: Colors.blue.shade200),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Container(height: 16, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                ],
              ),
            ),
          ],
        );
      case 'Sidebar':
        return Row(
          children: [
            Container(width: 40, color: Colors.blue.shade200),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Container(height: 20, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 16, color: Colors.grey.shade300),
                ],
              ),
            ),
          ],
        );
      case 'Grid Based':
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            Container(color: Colors.blue.shade200),
            Container(color: Colors.grey.shade300),
            Container(color: Colors.grey.shade300),
            Container(color: Colors.grey.shade300),
          ],
        );
      case 'Card Based':
        return Column(
          children: [
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 25,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 25,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      case 'Tabbed':
        return Column(
          children: [
            Row(
              children: [
                Container(width: 40, height: 20, color: Colors.blue.shade200),
                const SizedBox(width: 4),
                Container(width: 40, height: 20, color: Colors.grey.shade300),
                const SizedBox(width: 4),
                Container(width: 40, height: 20, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(child: Container(color: Colors.grey.shade100)),
          ],
        );
      default:
        return Container(color: Colors.grey.shade300);
    }
  }
}
