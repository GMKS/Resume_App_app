import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../services/premium_service.dart';
import '../services/ai_resume_service.dart';
// drag_drop_service removed; built-in flutter drag-drop used

/// Reusable base form wrapper for resume templates.
/// Provides:
/// - Form + validation
/// - Common text controllers
/// - Save logic (create / update)
/// - Helper to build text fields
/// - Drag & Drop functionality (Premium)
/// - Copy/Paste features (Premium)
class BaseResumeForm extends StatefulWidget {
  final SavedResume? existingResume;
  final String template;
  final Widget child;
  final List<String> extraKeys; // NEW: additional field keys
  final String? templateType; // NEW: for specific template handling
  final Map<String, dynamic>? initialData; // NEW: for imported data
  final List<Widget>? customSections; // NEW: for template-specific sections
  final Function(Map<String, dynamic>)?
  onDataChanged; // NEW: for real-time updates
  // NEW: Opt-in flag to show the Drag & Drop section ordering panel
  final bool showDragDropPanel;

  const BaseResumeForm({
    super.key,
    this.existingResume,
    required this.template,
    required this.child,
    this.extraKeys = const [],
    this.templateType,
    this.initialData,
    this.customSections,
    this.onDataChanged,
    this.showDragDropPanel = false,
  });

  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();

  /// Optional helper to access state (e.g., to trigger save from child):
  static _BaseResumeFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BaseResumeFormState>();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();
  // final _dragDropService = DragDropService();

  late final Map<String, TextEditingController> controllers;
  List<String> _draggableItems = [];
  BuildContext?
  _childContext; // context inside child subtree (where Scaffold lives)

  @override
  void initState() {
    super.initState();
    controllers = {
      'name': TextEditingController(),
      'email': TextEditingController(),
      'phone': TextEditingController(),
      'summary': TextEditingController(),
      'skills': TextEditingController(),
      'experience': TextEditingController(),
      'education': TextEditingController(),
    };
    for (final k in widget.extraKeys) {
      controllers.putIfAbsent(k, () => TextEditingController());
    }

    // Load initial data from import or existing resume
    if (widget.initialData != null) {
      _loadInitialData();
    } else if (widget.existingResume != null) {
      _loadData();
    }

    // Setup drag & drop items for premium users
    if (PremiumService.hasDragDropFeature) {
      _initializeDraggableItems();
    }
  }

  void _loadData() {
    final data = widget.existingResume!.data;
    controllers.forEach((k, c) => c.text = (data[k] ?? '').toString());
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    controllers.forEach((k, c) {
      if (data.containsKey(k)) {
        c.text = (data[k] ?? '').toString();
      }
    });

    // Notify parent of data change
    widget.onDataChanged?.call(data);
  }

  void _initializeDraggableItems() {
    _draggableItems = [
      'Personal Information',
      'Professional Summary',
      'Work Experience',
      'Education',
      'Skills',
      'Certifications',
      'Projects',
      'References',
    ];
  }

  /// Call this to validate + save the resume.
  Future<void> saveResume() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Try to show a helpful message even if the child Scaffold is below us
      try {
        final overlayCtx = Navigator.of(context).overlay?.context;
        final messenger = overlayCtx != null
            ? ScaffoldMessenger.maybeOf(overlayCtx)
            : ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      } catch (_) {}
      return;
    }

    // Enforce: block save if overlapping dates exist in work/education
    final overlapProblems = _detectDateOverlapsInControllers();
    if (overlapProblems.isNotEmpty) {
      try {
        final overlayCtx = Navigator.of(context).overlay?.context;
        final messenger = overlayCtx != null
            ? ScaffoldMessenger.maybeOf(overlayCtx)
            : ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save: overlapping dates found in ${overlapProblems.join(' and ')}. Please resolve before saving.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (_) {}
      return;
    }

    final Map<String, dynamic> data = {
      for (final e in controllers.entries) e.key: e.value.text,
    };

    final title = controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${controllers['name']!.text} Resume';

    final resume = SavedResume(
      id:
          widget.existingResume?.id ??
          ResumeStorageService.instance.generateId(),
      title: widget.existingResume?.title ?? title,
      template: widget.template,
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    await ResumeStorageService.instance.saveOrUpdate(resume);

    if (!mounted) return;
    final ctx = _childContext ?? context;
    try {
      // Prefer a messenger tied to the current Navigator overlay for reliability
      final overlayCtx =
          Navigator.of(ctx).overlay?.context ??
          Navigator.of(context).overlay?.context;
      final messenger = overlayCtx != null
          ? ScaffoldMessenger.maybeOf(overlayCtx)
          : (ScaffoldMessenger.maybeOf(ctx) ??
                ScaffoldMessenger.maybeOf(context));
      messenger?.showSnackBar(
        SnackBar(content: Text('${widget.template} resume saved')),
      );
    } catch (_) {}
    if (Navigator.canPop(ctx)) {
      Navigator.pop(ctx);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // --- Helpers: overlap detection for dynamic sections stored as JSON ---
  List<String> _detectDateOverlapsInControllers() {
    final issues = <String>[];

    bool overlapsFor(String? jsonStr) {
      if (jsonStr == null || jsonStr.trim().isEmpty) return false;
      try {
        final list = (jsonDecode(jsonStr) as List).cast<Map>();
        DateTime? parse(Object? v) {
          if (v == null) return null;
          try {
            return DateTime.tryParse(v.toString());
          } catch (_) {
            return null;
          }
        }

        bool overlaps(DateTime? s1, DateTime? e1, DateTime? s2, DateTime? e2) {
          if (s1 == null || s2 == null) return false; // need starts to compare
          final end1 = e1 ?? DateTime(9999, 12, 31);
          final end2 = e2 ?? DateTime(9999, 12, 31);
          int ym(DateTime d) => d.year * 12 + d.month;
          final s1m = ym(DateTime(s1.year, s1.month));
          final e1m = ym(DateTime(end1.year, end1.month));
          final s2m = ym(DateTime(s2.year, s2.month));
          final e2m = ym(DateTime(end2.year, end2.month));
          return s1m <= e2m && s2m <= e1m;
        }

        for (var i = 0; i < list.length; i++) {
          final a = list[i];
          final s1 = parse(a['startDate']);
          final e1 = parse(a['endDate']);
          for (var j = i + 1; j < list.length; j++) {
            final b = list[j];
            if (overlaps(s1, e1, parse(b['startDate']), parse(b['endDate']))) {
              return true;
            }
          }
        }
        return false;
      } catch (_) {
        // If parsing fails, do not block save on this field
        return false;
      }
    }

    // Check common keys used by templates using dynamic sections
    final workJson = controllers['workExperiences']?.text ?? '';
    final workJsonAlt = controllers['workExperiencesJson']?.text ?? '';
    final eduJson = controllers['educations']?.text ?? '';
    final eduJsonAlt = controllers['educationsJson']?.text ?? '';

    if (overlapsFor(workJson) || overlapsFor(workJsonAlt)) {
      issues.add('Work Experience');
    }
    if (overlapsFor(eduJson) || overlapsFor(eduJsonAlt)) {
      issues.add('Education');
    }

    return issues;
  }

  TextEditingController controllerFor(String key) =>
      controllers.putIfAbsent(key, () => TextEditingController());

  /// Helper to quickly build a labeled text field that ties into
  /// validation & controllers map with premium copy-paste features.
  Widget buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    bool enableDragDrop = false,
  }) {
    final controller = controllerFor(key);

    Future<void> generateForThisField() async {
      // Build a minimal context from other fields for better results
      final name = controllers['name']?.text ?? '';
      final summary = controllers['summary']?.text ?? '';
      final skills = controllers['skills']?.text ?? '';
      final seed = controller.text;
      try {
        final result = await AIResumeService.generateFromSeed(
          section: key,
          seed: seed,
          extraContext: [
            if (name.isNotEmpty) 'Name: $name',
            if (summary.isNotEmpty) 'Summary: $summary',
            if (skills.isNotEmpty) 'Skills: $skills',
          ].join('\n'),
        );
        controller.text = result;
        _notifyDataChanged();
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generated ${label.toLowerCase()}')),
          );
        } catch (_) {}
      } catch (e) {
        try {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('AI generate failed: $e')));
        } catch (_) {}
      }
    }

    Widget textField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        suffixIcon: PremiumService.hasCopyPasteFeature
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18),
                        SizedBox(width: 8),
                        Text('Copy'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'paste',
                    child: Row(
                      children: [
                        Icon(Icons.paste, size: 18),
                        SizedBox(width: 8),
                        Text('Paste'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear, size: 18),
                        SizedBox(width: 8),
                        Text('Clear'),
                      ],
                    ),
                  ),
                  if (PremiumService.hasAIFeatures)
                    const PopupMenuItem(
                      value: 'generate',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('Generate'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'generate') {
                    await generateForThisField();
                  } else {
                    await _handleTextFieldAction(controller, value);
                  }
                },
              )
            : null,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );

    // Wrap with drag-drop zone for premium users
    if (enableDragDrop &&
        PremiumService.hasDragDropFeature &&
        PremiumService.hasCopyPasteFeature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DragTarget<String>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: candidateData.isNotEmpty
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: textField,
            );
          },
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final String data = details.data;
            _notifyDataChanged();
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: textField,
    );
  }

  Future<void> _handleTextFieldAction(
    TextEditingController controller,
    String action,
  ) async {
    switch (action) {
      case 'copy':
        if (controller.text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: controller.text));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        break;
      case 'paste':
        final data = await Clipboard.getData('text/plain');
        if (data?.text != null) {
          controller.text = data!.text!;
          _notifyDataChanged();
        }
        break;
      case 'clear':
        controller.clear();
        _notifyDataChanged();
        break;
    }
  }

  void _notifyDataChanged() {
    final data = {for (final e in controllers.entries) e.key: e.value.text};
    widget.onDataChanged?.call(data);
  }

  /// Expose controllers if child wants direct access.
  Map<String, TextEditingController> get allControllers => controllers;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Custom sections (e.g., for Two Page template)
          if (widget.customSections != null) ...widget.customSections!,

          // Drag & Drop Section List for Premium Users
          if (widget.showDragDropPanel &&
              PremiumService.hasDragDropFeature &&
              PremiumService.hasCopyPasteFeature &&
              _draggableItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag & Drop Sections',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ) ??
                              const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reorder sections by dragging them up or down',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _draggableItems.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _draggableItems.removeAt(oldIndex);
                        _draggableItems.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _draggableItems[index];
                      return DraggableListItem(
                        key: ValueKey(item),
                        index: index,
                        onTap: () {
                          // Handle section tap - could navigate to specific form section
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            item,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Main form content
          Expanded(
            child: Builder(
              builder: (ctx) {
                _childContext = ctx;
                return widget.child;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Minimal DraggableListItem for use in ReorderableListView.builder
class DraggableListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final VoidCallback? onTap;

  const DraggableListItem({
    super.key,
    required this.index,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: child,
        trailing: const Icon(Icons.drag_handle),
        onTap: onTap,
      ),
    );
  }
}
