import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';

class BaseResumeForm extends StatefulWidget {
  final SavedResume? existingResume;
  final String template;
  final Widget child;

  const BaseResumeForm({
    super.key,
    required this.existingResume,
    required this.template,
    required this.child,
  });

  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> controllers;

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
    if (widget.existingResume != null) _loadData();
  }

  void _loadData() {
    controllers.forEach((key, controller) {
      controller.text = widget.existingResume!.data[key] ?? '';
    });
  }

  Future<void> saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = controllers.map(
      (key, controller) => MapEntry(key, controller.text),
    );
    final title = controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${controllers['name']!.text} Resume';

    final resume = SavedResume(
      id: widget.existingResume?.id ?? ResumeStorageService.generateId(),
      title: widget.existingResume?.title ?? title,
      template: widget.template,
      data: data,
      applications: widget.existingResume?.applications ?? [],
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ResumeStorageService.saveResume(resume);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.template} Resume saved successfully!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controllers[key],
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v?.isEmpty == true ? '$label is required' : null
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) =>
      Form(key: _formKey, child: widget.child);
}
