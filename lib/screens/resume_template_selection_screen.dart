import 'package:flutter/material.dart';
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';
import 'professional_resume_form_screen.dart';
import 'creative_resume_form_screen.dart';
import 'one_page_resume_form_screen.dart';
import '../services/resume_storage_service.dart';

class ResumeTemplateSelectionScreen extends StatefulWidget {
  const ResumeTemplateSelectionScreen({super.key});

  @override
  State<ResumeTemplateSelectionScreen> createState() =>
      _ResumeTemplateSelectionScreenState();
}

class _ResumeTemplateSelectionScreenState
    extends State<ResumeTemplateSelectionScreen> {
  int _selectedIndex = 0;

  final templates = <_TemplateMeta>[
    _TemplateMeta(
      title: 'Classic',
      icon: Icons.description_outlined,
      bestFor: 'General',
      style: 'Balanced traditional layout',
      requiredFields: const ['Name', 'Email', 'Phone'],
      screen: const ClassicResumeFormScreen(),
      prefix: 'classic',
    ),
    _TemplateMeta(
      title: 'Modern',
      icon: Icons.auto_awesome,
      bestFor: 'Creative',
      style: 'Modern accent headers',
      requiredFields: const ['Name', 'Summary'],
      screen: const ModernResumeFormScreen(),
      prefix: 'modern',
    ),
    _TemplateMeta(
      title: 'Minimal',
      icon: Icons.crop_square,
      bestFor: 'ATS',
      style: 'Clean single-column',
      requiredFields: const ['Name', 'Experience'],
      screen: const MinimalResumeFormScreen(),
      prefix: 'minimal',
    ),
    _TemplateMeta(
      title: 'Professional',
      icon: Icons.work_outline,
      bestFor: 'Corporate',
      style: 'Executive summary',
      requiredFields: const ['Name', 'Executive Summary'],
      screen: const ProfessionalResumeFormScreen(),
      prefix: 'professional',
    ),
    _TemplateMeta(
      title: 'Creative',
      icon: Icons.palette_outlined,
      bestFor: 'Design',
      style: 'Color blocks & photo',
      requiredFields: const ['Name', 'Portfolio'],
      screen: const CreativeResumeFormScreen(),
      prefix: 'creative',
    ),
    _TemplateMeta(
      title: 'One Page',
      icon: Icons.pageview_outlined,
      bestFor: 'Concise',
      style: 'Compact single page',
      requiredFields: const ['Name', 'Summary', 'Experience'],
      screen: const OnePageResumeFormScreen(),
      prefix: 'onepage',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Resume Template')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ExpansionPanelList.radio(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.zero,
                initialOpenPanelValue: _selectedIndex, // auto-open selected
                children: List.generate(templates.length, (index) {
                  final t = templates[index];
                  return ExpansionPanelRadio(
                    canTapOnHeader: true,
                    value: index,
                    headerBuilder: (_, isOpen) => ListTile(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _selectedIndex == index
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(.15)
                                : Colors.grey.shade200,
                          ),
                          Icon(
                            t.icon,
                            color: _selectedIndex == index
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[700],
                          ),
                        ],
                      ),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Best For: ${t.bestFor}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: _selectedIndex == index
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined, size: 18),
                    ),
                    body: _TemplateDetail(meta: t),
                  );
                }),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Template'),
                      onPressed: () {
                        final name = templates[_selectedIndex].title;
                        ResumeStorageService.instance.saveEmptyTemplate(name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name saved to Saved Resumes'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Continue', overflow: TextOverflow.ellipsis),
                      onPressed: () {
                        final meta = templates[_selectedIndex];
                        _showRequiredFieldsSheet(context, meta);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequiredFieldsSheet(BuildContext context, _TemplateMeta meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        meta.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meta.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    children: [
                      _sheetSectionTitle(context, 'Best For'),
                      Text(meta.bestFor, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 14),
                      _sheetSectionTitle(context, 'Style'),
                      Text(meta.style, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 14),
                      _sheetSectionTitle(context, 'Required Fields'),
                      const SizedBox(height: 6),
                      ...meta.requiredFields.map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  f,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Start Form'),
                            onPressed: () {
                              Navigator.pop(ctx); // close sheet
                              final target = meta.screen;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => target),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetSectionTitle(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _TemplateMeta {
  final String title;
  final IconData icon;
  final String bestFor;
  final String style;
  final List<String> requiredFields;
  final Widget screen;
  final String prefix;
  _TemplateMeta({
    required this.title,
    required this.icon,
    required this.bestFor,
    required this.style,
    required this.requiredFields,
    required this.screen,
    required this.prefix,
  });
}

class _TemplateDetail extends StatelessWidget {
  final _TemplateMeta meta;
  const _TemplateDetail({required this.meta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Style', theme),
          Text(
            meta.style,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _label('Required Fields', theme),
          // Scrollable area if list is long
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: meta.requiredFields.length,
                itemBuilder: (ctx, i) {
                  final field = meta.requiredFields[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            field,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: .5,
        color: theme.colorScheme.primary,
      ),
    ),
  );
}
