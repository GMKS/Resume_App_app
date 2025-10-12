import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import 'modern_resume_preview.dart';

class InteractiveModernResumeScreen extends StatefulWidget {
  final SavedResume? existingResume;

  const InteractiveModernResumeScreen({super.key, this.existingResume});

  @override
  State<InteractiveModernResumeScreen> createState() =>
      _InteractiveModernResumeScreenState();
}

class _InteractiveModernResumeScreenState
    extends State<InteractiveModernResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _editingField;

  // Controllers for all fields
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'location': TextEditingController(),
    'linkedin': TextEditingController(),
    'github': TextEditingController(),
    'portfolio': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
    'certifications': TextEditingController(),
    'achievements': TextEditingController(),
    'hobbies': TextEditingController(),
  };

  // Draggable field order
  final List<String> _fieldOrder = [
    'name',
    'contact',
    'summary',
    'skills',
    'workExperience',
    'education',
    'certifications',
    'achievements',
    'hobbies',
  ];

  final List<Map<String, dynamic>> _workExperience = [];
  final List<Map<String, dynamic>> _education = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingResume != null) {
      final data = widget.existingResume!.data;
      final info = data['personalInfo'] ?? {};

      _controllers['name']?.text = info['name'] ?? '';
      _controllers['email']?.text = info['email'] ?? '';
      _controllers['phone']?.text = info['phone'] ?? '';
      _controllers['location']?.text = info['location'] ?? '';
      _controllers['linkedin']?.text = info['linkedin'] ?? '';
      _controllers['github']?.text = info['github'] ?? '';
      _controllers['portfolio']?.text = info['portfolio'] ?? '';
      _controllers['summary']?.text = data['summary'] ?? '';
      _controllers['skills']?.text = data['skills'] ?? '';
      _controllers['certifications']?.text = data['certifications'] ?? '';
      _controllers['achievements']?.text = data['achievements'] ?? '';
      _controllers['hobbies']?.text = data['hobbies'] ?? '';

      // Load work experience
      final work = List<Map<String, dynamic>>.from(
        data['workExperience'] ?? [],
      );
      _workExperience.addAll(work);

      // Load education
      final edu = List<Map<String, dynamic>>.from(data['education'] ?? []);
      _education.addAll(edu);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startEditing(String fieldKey) {
    setState(() {
      _editingField = fieldKey;
    });
  }

  void _stopEditing() {
    setState(() {
      _editingField = null;
    });
  }

  Widget _buildClickableField({
    required String fieldKey,
    required String label,
    required String value,
    IconData? icon,
    int maxLines = 1,
  }) {
    final isEditing = _editingField == fieldKey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: isEditing
          ? Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _controllers[fieldKey],
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onFieldSubmitted: (_) => _stopEditing(),
                    autofocus: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _stopEditing,
                ),
              ],
            )
          : GestureDetector(
              onTap: () => _startEditing(fieldKey),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'Click to add $label' : value,
                        style: TextStyle(
                          color: value.isEmpty
                              ? Colors.grey.shade500
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 200,
          child: _buildClickableField(
            fieldKey: 'email',
            label: 'Email',
            value: _controllers['email']?.text ?? '',
            icon: Icons.email,
          ),
        ),
        SizedBox(
          width: 150,
          child: _buildClickableField(
            fieldKey: 'phone',
            label: 'Phone',
            value: _controllers['phone']?.text ?? '',
            icon: Icons.phone,
          ),
        ),
        SizedBox(
          width: 180,
          child: _buildClickableField(
            fieldKey: 'location',
            label: 'Location',
            value: _controllers['location']?.text ?? '',
            icon: Icons.location_on,
          ),
        ),
        SizedBox(
          width: 180,
          child: _buildClickableField(
            fieldKey: 'linkedin',
            label: 'LinkedIn',
            value: _controllers['linkedin']?.text ?? '',
            icon: Icons.link,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSection(String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return _buildClickableField(
          fieldKey: 'name',
          label: 'Full Name',
          value: _controllers['name']?.text ?? '',
          icon: Icons.person,
        );

      case 'contact':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildContactRow(),
          ],
        );

      case 'summary':
        return _buildClickableField(
          fieldKey: 'summary',
          label: 'Professional Summary',
          value: _controllers['summary']?.text ?? '',
          icon: Icons.description,
          maxLines: 4,
        );

      case 'skills':
        return _buildClickableField(
          fieldKey: 'skills',
          label: 'Skills (comma separated)',
          value: _controllers['skills']?.text ?? '',
          icon: Icons.build,
          maxLines: 2,
        );

      case 'workExperience':
        return _buildWorkExperienceSection();

      case 'education':
        return _buildEducationSection();

      case 'certifications':
        return _buildClickableField(
          fieldKey: 'certifications',
          label: 'Certifications',
          value: _controllers['certifications']?.text ?? '',
          icon: Icons.verified,
          maxLines: 3,
        );

      case 'achievements':
        return _buildClickableField(
          fieldKey: 'achievements',
          label: 'Achievements',
          value: _controllers['achievements']?.text ?? '',
          icon: Icons.emoji_events,
          maxLines: 3,
        );

      case 'hobbies':
        return _buildClickableField(
          fieldKey: 'hobbies',
          label: 'Hobbies & Interests',
          value: _controllers['hobbies']?.text ?? '',
          icon: Icons.sports_esports,
          maxLines: 2,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWorkExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Work Experience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addWorkExperience,
            ),
          ],
        ),
        ..._workExperience.asMap().entries.map((entry) {
          final index = entry.key;
          final work = entry.value;
          return _buildWorkExperienceItem(work, index);
        }),
      ],
    );
  }

  Widget _buildWorkExperienceItem(Map<String, dynamic> work, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${work['role'] ?? 'Job Title'} at ${work['company'] ?? 'Company'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editWorkExperience(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeWorkExperience(index),
                ),
              ],
            ),
            Text(
              '${work['startDate'] ?? ''} - ${work['endDate'] ?? 'Present'}',
            ),
            if (work['description'] != null &&
                work['description'].toString().isNotEmpty)
              Text(work['description'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Education',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add), onPressed: _addEducation),
          ],
        ),
        ..._education.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;
          return _buildEducationItem(edu, index);
        }),
      ],
    );
  }

  Widget _buildEducationItem(Map<String, dynamic> edu, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${edu['degree'] ?? 'Degree'} from ${edu['institution'] ?? 'Institution'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editEducation(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeEducation(index),
                ),
              ],
            ),
            Text('${edu['startDate'] ?? ''} - ${edu['endDate'] ?? 'Present'}'),
          ],
        ),
      ),
    );
  }

  void _addWorkExperience() {
    setState(() {
      _workExperience.add({
        'role': '',
        'company': '',
        'startDate': '',
        'endDate': '',
        'description': '',
      });
    });
  }

  void _editWorkExperience(int index) {
    final work = _workExperience[index];
    final roleController = TextEditingController(text: work['role'] ?? '');
    final companyController = TextEditingController(
      text: work['company'] ?? '',
    );
    final startDateController = TextEditingController(
      text: work['startDate'] ?? '',
    );
    final endDateController = TextEditingController(
      text: work['endDate'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: work['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Work Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(labelText: 'End Date'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _workExperience[index] = {
                  'role': roleController.text,
                  'company': companyController.text,
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                  'description': descriptionController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeWorkExperience(int index) {
    setState(() {
      _workExperience.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      _education.add({
        'degree': '',
        'institution': '',
        'startDate': '',
        'endDate': '',
      });
    });
  }

  void _editEducation(int index) {
    final edu = _education[index];
    final degreeController = TextEditingController(text: edu['degree'] ?? '');
    final institutionController = TextEditingController(
      text: edu['institution'] ?? '',
    );
    final startDateController = TextEditingController(
      text: edu['startDate'] ?? '',
    );
    final endDateController = TextEditingController(text: edu['endDate'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeController,
                decoration: const InputDecoration(labelText: 'Degree'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(labelText: 'End Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _education[index] = {
                  'degree': degreeController.text,
                  'institution': institutionController.text,
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeEducation(int index) {
    setState(() {
      _education.removeAt(index);
    });
  }

  Future<void> _saveResume() async {
    // Create resume data
    final data = {
      'personalInfo': {
        'name': _controllers['name']?.text ?? '',
        'email': _controllers['email']?.text ?? '',
        'phone': _controllers['phone']?.text ?? '',
        'location': _controllers['location']?.text ?? '',
        'linkedin': _controllers['linkedin']?.text ?? '',
        'github': _controllers['github']?.text ?? '',
        'portfolio': _controllers['portfolio']?.text ?? '',
      },
      'summary': _controllers['summary']?.text ?? '',
      'skills': _controllers['skills']?.text ?? '',
      'workExperience': _workExperience,
      'education': _education,
      'certifications': _controllers['certifications']?.text ?? '',
      'achievements': _controllers['achievements']?.text ?? '',
      'hobbies': _controllers['hobbies']?.text ?? '',
      'fieldOrder': _fieldOrder,
    };

    final resume = SavedResume(
      id:
          widget.existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _controllers['name']?.text.isNotEmpty == true
          ? '${_controllers['name']?.text} Resume'
          : 'Modern Resume',
      template: 'Modern',
      data: data,
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ResumeStorageService.instance.saveOrUpdate(resume);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Modern Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () {
              // Create resume data and navigate to preview
              _saveResume().then((_) {
                final resume = SavedResume(
                  id:
                      widget.existingResume?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _controllers['name']?.text.isNotEmpty == true
                      ? '${_controllers['name']?.text} Resume'
                      : 'Modern Resume',
                  template: 'Modern',
                  data: {
                    'personalInfo': {
                      'name': _controllers['name']?.text ?? '',
                      'email': _controllers['email']?.text ?? '',
                      'phone': _controllers['phone']?.text ?? '',
                      'location': _controllers['location']?.text ?? '',
                      'linkedin': _controllers['linkedin']?.text ?? '',
                      'github': _controllers['github']?.text ?? '',
                      'portfolio': _controllers['portfolio']?.text ?? '',
                    },
                    'summary': _controllers['summary']?.text ?? '',
                    'skills': _controllers['skills']?.text ?? '',
                    'workExperience': _workExperience,
                    'education': _education,
                    'certifications':
                        _controllers['certifications']?.text ?? '',
                    'achievements': _controllers['achievements']?.text ?? '',
                    'hobbies': _controllers['hobbies']?.text ?? '',
                    'fieldOrder': _fieldOrder,
                  },
                  createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModernResumePreview(resume: resume),
                  ),
                );
              });
            },
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveResume),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click on any field to edit. Drag sections to reorder them.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // Draggable content
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _fieldOrder.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _fieldOrder.removeAt(oldIndex);
                    _fieldOrder.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final fieldKey = _fieldOrder[index];
                  return Container(
                    key: ValueKey(fieldKey),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDraggableSection(fieldKey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
