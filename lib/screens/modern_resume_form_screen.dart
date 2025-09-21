import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';

class ModernResumeFormScreen extends StatefulWidget {
  final SavedResume? existingResume;
  const ModernResumeFormScreen({super.key, this.existingResume});

  @override
  State<ModernResumeFormScreen> createState() => _ModernResumeFormScreenState();
}

class _ModernResumeFormScreenState extends State<ModernResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'linkedin': TextEditingController(),
    'github': TextEditingController(),
    'portfolio': TextEditingController(),
    'certifications': TextEditingController(),
    'achievements': TextEditingController(),
    'hobbies': TextEditingController(),
  };

  // Profile picture
  ImageProvider? _profileImage;

  // Skills
  final List<String> _allSkills = [
    'Flutter',
    'Dart',
    'JavaScript',
    'Python',
    'UI/UX',
    'React',
    'Figma',
    'Java',
    'C++',
    'SQL',
  ];
  final Map<String, double> _skillRatings = {};

  // Work/Education Timeline
  final List<Map<String, dynamic>> _workTimeline = [];
  final List<Map<String, dynamic>> _eduTimeline = [];

  // For adding new work/edu
  final _workCompany = TextEditingController();
  final _workRole = TextEditingController();
  DateTime? _workStart, _workEnd;

  final _eduSchool = TextEditingController();
  final _eduDegree = TextEditingController();
  DateTime? _eduStart, _eduEnd;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _workCompany.dispose();
    _workRole.dispose();
    _eduSchool.dispose();
    _eduDegree.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    // For demo: use a placeholder, or use image_picker for real app
    setState(() {
      _profileImage = const AssetImage('assets/profile_placeholder.png');
    });
  }

  void _addWork() {
    if (_workCompany.text.isEmpty ||
        _workRole.text.isEmpty ||
        _workStart == null) {
      return;
    }
    setState(() {
      _workTimeline.add({
        'company': _workCompany.text,
        'role': _workRole.text,
        'start': _workStart,
        'end': _workEnd,
      });
      _workCompany.clear();
      _workRole.clear();
      _workStart = null;
      _workEnd = null;
    });
  }

  void _addEdu() {
    if (_eduSchool.text.isEmpty ||
        _eduDegree.text.isEmpty ||
        _eduStart == null) {
      return;
    }
    setState(() {
      _eduTimeline.add({
        'school': _eduSchool.text,
        'degree': _eduDegree.text,
        'start': _eduStart,
        'end': _eduEnd,
      });
      _eduSchool.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    ValueChanged<DateTime> onPicked, {
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _controllers.map((k, c) => MapEntry(k, c.text));
    data['skills'] = _skillRatings.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    data['workTimeline'] = jsonEncode(
      _workTimeline
          .map(
            (e) => {
              'company': e['company'],
              'role': e['role'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
    );
    data['eduTimeline'] = jsonEncode(
      _eduTimeline
          .map(
            (e) => {
              'school': e['school'],
              'degree': e['degree'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
    );
    final title = _controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${_controllers['name']!.text} Resume';
    final resume = SavedResume(
      id:
          widget.existingResume?.id ??
          ResumeStorageService.instance.generateId(),
      title: widget.existingResume?.title ?? title,
      template: 'Modern',
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );
    await ResumeStorageService.instance.saveOrUpdate(resume);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Modern Resume saved!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.purple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Resume'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Profile + Contact
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: accent.withOpacity(0.2),
                          backgroundImage: _profileImage,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _modernContactRow(
                              Icons.person,
                              _controllers['name']!,
                              'Full Name',
                            ),
                            _modernContactRow(
                              Icons.email,
                              _controllers['email']!,
                              'Email',
                            ),
                            _modernContactRow(
                              Icons.phone,
                              _controllers['phone']!,
                              'Phone',
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.linked_camera,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'LinkedIn',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.code,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'GitHub',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.web,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'Portfolio',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Stylish Summary
              Card(
                color: accent.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _controllers['summary'],
                          maxLines: 3,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Summary',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Skills
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Skills',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSkills.map((skill) {
                          final selected = _skillRatings.containsKey(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            selectedColor: accent.withOpacity(0.2),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _skillRatings[skill] = 3;
                                } else {
                                  _skillRatings.remove(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_skillRatings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._skillRatings.entries.map(
                          (e) => Row(
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: e.value,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: '${e.value.round()}',
                                  onChanged: (v) =>
                                      setState(() => _skillRatings[e.key] = v),
                                  activeColor: accent,
                                ),
                              ),
                              Text('⭐' * e.value.round()),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Work Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🏢', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Work Experience',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._workTimeline.map(
                        (w) => _timelineTile(
                          title: w['role'],
                          subtitle: w['company'],
                          start: w['start'],
                          end: w['end'],
                          color: accent,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _workCompany,
                              decoration: const InputDecoration(
                                labelText: 'Company',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _workRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workStart == null
                                    ? 'Start Date'
                                    : "${_workStart!.year}-${_workStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workStart = d),
                                initial: _workStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workEnd == null
                                    ? 'End Date'
                                    : "${_workEnd!.year}-${_workEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workEnd = d),
                                initial: _workEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: _addWork,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Education Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎓', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Education',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._eduTimeline.map(
                        (e) => _timelineTile(
                          title: e['degree'],
                          subtitle: e['school'],
                          start: e['start'],
                          end: e['end'],
                          color: Colors.teal,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _eduSchool,
                              decoration: const InputDecoration(
                                labelText: 'School/College',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _eduDegree,
                              decoration: const InputDecoration(
                                labelText: 'Degree',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduStart == null
                                    ? 'Start Date'
                                    : "${_eduStart!.year}-${_eduStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduStart = d),
                                initial: _eduStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduEnd == null
                                    ? 'End Date'
                                    : "${_eduEnd!.year}-${_eduEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduEnd = d),
                                initial: _eduEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: _addEdu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Certifications
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Certifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _controllers['certifications']!.text
                            .split(',')
                            .where((c) => c.trim().isNotEmpty)
                            .map(
                              (c) => Chip(
                                label: Text(c.trim()),
                                avatar: const Icon(Icons.verified),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Achievements & Hobbies
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Achievements & Hobbies',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controllers['achievements'],
                        decoration: const InputDecoration(
                          labelText: 'Achievements (comma separated)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controllers['hobbies'],
                        decoration: const InputDecoration(
                          labelText: 'Hobbies (comma separated)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ..._controllers['achievements']!.text
                              .split(',')
                              .where((a) => a.trim().isNotEmpty)
                              .map(
                                (a) => Chip(
                                  label: Text(a.trim()),
                                  avatar: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                ),
                              ),
                          ..._controllers['hobbies']!.text
                              .split(',')
                              .where((h) => h.trim().isNotEmpty)
                              .map(
                                (h) => Chip(
                                  label: Text(h.trim()),
                                  avatar: const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Modern Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveResume,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernContactRow(
    IconData icon,
    TextEditingController controller,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineTile({
    required String title,
    required String subtitle,
    required DateTime? start,
    required DateTime? end,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 40, color: color.withOpacity(0.4)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.black87)),
                Text(
                  '${start != null ? "${start.year}-${start.month.toString().padLeft(2, '0')}" : ''}'
                  ' - '
                  '${end != null ? "${end.year}-${end.month.toString().padLeft(2, '0')}" : 'Present'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
