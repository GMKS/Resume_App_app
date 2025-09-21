import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';

/// Reusable base form wrapper for resume templates.
/// Provides:
/// - Form + validation
/// - Common text controllers
/// - Save logic (create / update)
/// - Helper to build text fields
class BaseResumeForm extends StatefulWidget {
  final SavedResume? existingResume;
  final String template;
  final Widget child;
  final List<String> extraKeys; // NEW: additional field keys

  const BaseResumeForm({
    super.key,
    this.existingResume,
    required this.template,
    required this.child,
    this.extraKeys = const [],
  });

  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();

  /// Optional helper to access state (e.g., to trigger save from child):
  static _BaseResumeFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BaseResumeFormState>();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> controllers;

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
    if (widget.existingResume != null) _loadData();
  }

  void _loadData() {
    final data = widget.existingResume!.data;
    controllers.forEach((k, c) => c.text = (data[k] ?? '').toString());
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
  /// validation & controllers map.
  Widget buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controllerFor(key),
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  /// Expose controllers if child wants direct access.
  Map<String, TextEditingController> get allControllers => controllers;

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: widget.child);
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
