import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../services/premium_service.dart';
import '../services/drag_drop_service.dart';

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
  });

  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();

  /// Optional helper to access state (e.g., to trigger save from child):
  static _BaseResumeFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BaseResumeFormState>();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();
  final _dragDropService = DragDropService();

  late final Map<String, TextEditingController> controllers;
  List<String> _draggableItems = [];

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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${widget.template} resume saved')));
    Navigator.pop(context);
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

    Widget textField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        isDense: true,
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
                ],
                onSelected: (value) =>
                    _handleTextFieldAction(controller, value),
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
          onWillAcceptWithDetails: (data) => true,
          onAcceptWithDetails: (data) {
            controller.text = data;
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
          if (PremiumService.hasDragDropFeature &&
              PremiumService.hasCopyPasteFeature &&
              _draggableItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.drag_handle, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Drag & Drop Sections',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reorder sections by dragging them up or down',
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
          Expanded(child: widget.child),
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
