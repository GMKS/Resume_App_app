import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';

class ClassicResumeFormScreen extends StatefulWidget {
  final SavedResume? existingResume;
  const ClassicResumeFormScreen({super.key, this.existingResume});

  @override
  State<ClassicResumeFormScreen> createState() =>
      _ClassicResumeFormScreenState();
}

class _ClassicResumeFormScreenState extends State<ClassicResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
    'certifications': TextEditingController(),
    'education': TextEditingController(),
    'company': TextEditingController(),
    'position': TextEditingController(),
    'workDesc': TextEditingController(),
  };

  DateTime? _workStart, _workEnd;
  final List<String> _skillsList = [
    'Java',
    'Core Java',
    'Java Full Stack',
    'JavaScript',
    'Python',
    'C++',
    'C#',
    'SQL',
    'HTML',
    'CSS',
    'Dart',
    'Flutter',
    'React',
    'Angular',
    'Spring Boot',
  ];
  List<String> _filteredSkills = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingResume != null) {
      final data = widget.existingResume!.data;
      _controllers.forEach((k, c) => c.text = data[k] ?? '');
      if (data['workStart'] != null) {
        _workStart = DateTime.tryParse(data['workStart']!);
      }
      if (data['workEnd'] != null) {
        _workEnd = DateTime.tryParse(data['workEnd']!);
      }
    }
    _controllers['skills']!.addListener(_onSkillChanged);
  }

  void _onSkillChanged() {
    final input = _controllers['skills']!.text.toLowerCase();
    setState(() {
      _filteredSkills = input.isEmpty
          ? []
          : _skillsList
                .where((s) => s.toLowerCase().startsWith(input))
                .toList();
    });
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_workStart ?? DateTime.now())
        : (_workEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _workStart = picked;
        } else {
          _workEnd = picked;
        }
      });
    }
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _controllers.map((k, c) => MapEntry(k, c.text));
    if (_workStart != null) data['workStart'] = _workStart!.toIso8601String();
    if (_workEnd != null) data['workEnd'] = _workEnd!.toIso8601String();
    final title = _controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${_controllers['name']!.text} Resume';
    final resume = SavedResume(
      id: widget.existingResume?.id ?? ResumeStorageService.generateId(),
      title: widget.existingResume?.title ?? title,
      template: 'Classic',
      data: data,
      applications: widget.existingResume?.applications ?? [],
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ResumeStorageService.saveResume(resume);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resume saved!')));
      Navigator.pop(context);
    }
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        fontFamily: 'Calibri',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classic Resume',
          style: TextStyle(fontFamily: 'Times New Roman', color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _sectionTitle('Contact Info'),
            _buildField('name', 'Full Name', required: true),
            _buildField(
              'email',
              'Email',
              required: true,
              keyboard: TextInputType.emailAddress,
            ),
            _buildField('phone', 'Phone', keyboard: TextInputType.phone),

            _sectionTitle('Summary'),
            _buildField('summary', 'Professional Summary', maxLines: 3),

            _sectionTitle('Skills'),
            Stack(
              children: [
                _buildField(
                  'skills',
                  'Type to search/add skills (e.g. Ja...)',
                  onChanged: (_) => _onSkillChanged(),
                ),
                if (_filteredSkills.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 56,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListView(
                        shrinkWrap: true,
                        children: _filteredSkills
                            .map(
                              (skill) => ListTile(
                                title: Text(
                                  skill,
                                  style: const TextStyle(fontFamily: 'Arial'),
                                ),
                                onTap: () {
                                  _controllers['skills']!.text = skill;
                                  setState(() => _filteredSkills.clear());
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),

            _sectionTitle('Work Experience'),
            _buildField('company', 'Company Name'),
            _buildField('position', 'Position'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _workStart == null
                            ? ''
                            : "${_workStart!.year}-${_workStart!.month.toString().padLeft(2, '0')}-${_workStart!.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontFamily: 'Arial'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _workEnd == null
                            ? ''
                            : "${_workEnd!.year}-${_workEnd!.month.toString().padLeft(2, '0')}-${_workEnd!.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontFamily: 'Arial'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildField('workDesc', 'Description', maxLines: 2),

            _sectionTitle('Education'),
            _buildField('education', 'Education Details', maxLines: 2),

            _sectionTitle('Certifications'),
            _buildField('certifications', 'Certifications', maxLines: 2),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Save Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: 'Arial', fontSize: 16),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
