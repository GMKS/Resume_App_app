import 'package:flutter/material.dart';
import '../services/ai_text_enhancement_service.dart';

/// Dynamic Work Experience Entry Model
class WorkExperience {
  String id;
  String jobTitle;
  String company;
  String location;
  DateTime? startDate;
  DateTime? endDate;
  String description;
  List<String> achievements;
  bool isCurrentlyWorking;

  WorkExperience({
    required this.id,
    this.jobTitle = '',
    this.company = '',
    this.location = '',
    this.startDate,
    this.endDate,
    this.description = '',
    this.achievements = const [],
    this.isCurrentlyWorking = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'company': company,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'achievements': achievements,
      'isCurrentlyWorking': isCurrentlyWorking,
    };
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'],
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'] ?? '',
      achievements: List<String>.from(json['achievements'] ?? []),
      isCurrentlyWorking: json['isCurrentlyWorking'] ?? false,
    );
  }

  bool hasData() {
    return jobTitle.isNotEmpty ||
        company.isNotEmpty ||
        location.isNotEmpty ||
        description.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        achievements.isNotEmpty;
  }
}

/// Dynamic Education Entry Model
class Education {
  String id;
  String degree;
  String institution;
  String location;
  DateTime? startDate;
  DateTime? endDate;
  String gpa;
  String description;

  Education({
    required this.id,
    this.degree = '',
    this.institution = '',
    this.location = '',
    this.startDate,
    this.endDate,
    this.gpa = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'degree': degree,
      'institution': institution,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'gpa': gpa,
      'description': description,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      degree: json['degree'] ?? '',
      institution: json['institution'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      gpa: json['gpa'] ?? '',
      description: json['description'] ?? '',
    );
  }

  bool hasData() {
    return degree.isNotEmpty ||
        institution.isNotEmpty ||
        location.isNotEmpty ||
        gpa.isNotEmpty ||
        description.isNotEmpty ||
        startDate != null ||
        endDate != null;
  }
}

/// Custom Field Entry Model
class CustomField {
  String id;
  String label;
  String content;

  CustomField({required this.id, this.label = '', this.content = ''});

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'content': content};
  }

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      id: json['id'],
      label: json['label'] ?? '',
      content: json['content'] ?? '',
    );
  }

  bool hasData() {
    return label.isNotEmpty || content.isNotEmpty;
  }
}

/// Dynamic Work Experience Section Widget
class DynamicWorkExperienceSection extends StatefulWidget {
  final List<WorkExperience> workExperiences;
  final Function(List<WorkExperience>) onWorkExperiencesChanged;
  final Color? accentColor;
  final bool atsFriendly;

  const DynamicWorkExperienceSection({
    super.key,
    required this.workExperiences,
    required this.onWorkExperiencesChanged,
    this.accentColor,
    this.atsFriendly = false,
  });

  @override
  State<DynamicWorkExperienceSection> createState() =>
      _DynamicWorkExperienceSectionState();
}

class _DynamicWorkExperienceSectionState
    extends State<DynamicWorkExperienceSection> {
  // Controllers for description fields to fix AI text not showing
  final Map<String, TextEditingController> _descriptionControllers = {};

  @override
  void dispose() {
    // Clean up controllers
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getDescriptionController(
    String id,
    String initialText,
  ) {
    if (!_descriptionControllers.containsKey(id)) {
      _descriptionControllers[id] = TextEditingController(text: initialText);
    }
    // Update text if it changed
    if (_descriptionControllers[id]!.text != initialText) {
      _descriptionControllers[id]!.text = initialText;
    }
    return _descriptionControllers[id]!;
  }

  bool _overlaps(DateTime? s1, DateTime? e1, DateTime? s2, DateTime? e2) {
    if (s1 == null || s2 == null) return false; // can't compare without starts
    final end1 = e1 ?? DateTime(9999, 12, 31);
    final end2 = e2 ?? DateTime(9999, 12, 31);
    int ym(DateTime d) => d.year * 12 + d.month;
    final s1m = ym(DateTime(s1.year, s1.month));
    final e1m = ym(DateTime(end1.year, end1.month));
    final s2m = ym(DateTime(s2.year, s2.month));
    final e2m = ym(DateTime(end2.year, end2.month));
    return s1m <= e2m && s2m <= e1m;
  }

  List<String> _findOverlaps() {
    final msgs = <String>[];
    final list = widget.workExperiences;
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        if (_overlaps(
          list[i].startDate,
          list[i].endDate,
          list[j].startDate,
          list[j].endDate,
        )) {
          msgs.add('Experience ${i + 1} overlaps with Experience ${j + 1}');
        }
      }
    }
    return msgs;
  }

  void _addWorkExperience() {
    final newExperience = WorkExperience(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final updatedList = [...widget.workExperiences, newExperience];
    widget.onWorkExperiencesChanged(updatedList);
  }

  void _removeWorkExperience(String id) {
    final updatedList = widget.workExperiences
        .where((exp) => exp.id != id)
        .toList();
    widget.onWorkExperiencesChanged(updatedList);
  }

  void _updateWorkExperience(int index, WorkExperience experience) {
    final updatedList = [...widget.workExperiences];
    updatedList[index] = experience;
    widget.onWorkExperiencesChanged(updatedList);
  }

  void _showAIEnhancement(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onUpdate,
  ) {
    AITextEnhancementService.showEnhancementDialog(
      context,
      controller,
      onUpdate,
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    Function(DateTime?) onPicked, {
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.atsFriendly
        ? (widget.accentColor ?? Colors.black87)
        : (widget.accentColor ?? Colors.blue);
    final overlaps = _findOverlaps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Experience button (removed title since it's in card header)
        Row(
          children: [
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addWorkExperience,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Experience'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.atsFriendly
                    ? Colors.black87
                    : accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        if (overlaps.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overlapping work experience dates detected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...overlaps.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m, style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.workExperiences.isEmpty)
          Card(
            elevation: widget.atsFriendly ? 0 : null,
            shape: widget.atsFriendly
                ? RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!widget.atsFriendly)
                    Icon(Icons.work_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No work experience added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Experience" to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...widget.workExperiences.asMap().entries.map((entry) {
            final index = entry.key;
            final experience = entry.value;

            return Card(
              elevation: widget.atsFriendly ? 0 : null,
              shape: widget.atsFriendly
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Experience ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeWorkExperience(experience.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove this experience',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: experience.jobTitle,
                            decoration: const InputDecoration(
                              labelText: 'Job Title *',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              experience.jobTitle = value;
                              _updateWorkExperience(index, experience);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: experience.company,
                            decoration: const InputDecoration(
                              labelText: 'Company *',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              experience.company = value;
                              _updateWorkExperience(index, experience);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: experience.location,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        experience.location = value;
                        _updateWorkExperience(index, experience);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(context, (date) {
                              setState(() {
                                experience.startDate = date;
                                _updateWorkExperience(index, experience);
                              });
                            }, initial: experience.startDate),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              experience.startDate == null
                                  ? 'Start Date'
                                  : '${experience.startDate!.month}/${experience.startDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: experience.isCurrentlyWorking
                                ? null
                                : () => _pickDate(context, (date) {
                                    setState(() {
                                      experience.endDate = date;
                                      _updateWorkExperience(index, experience);
                                    });
                                  }, initial: experience.endDate),
                            icon: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: experience.isCurrentlyWorking
                                  ? Colors.grey
                                  : null,
                            ),
                            label: Text(
                              experience.isCurrentlyWorking
                                  ? 'Present'
                                  : experience.endDate == null
                                  ? 'End Date'
                                  : '${experience.endDate!.month}/${experience.endDate!.year}',
                              style: TextStyle(
                                color: experience.isCurrentlyWorking
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text(
                        'Currently working here',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: experience.isCurrentlyWorking,
                      onChanged: (bool? value) {
                        setState(() {
                          // If checking this one, uncheck all others
                          if (value == true) {
                            final updatedList = [...widget.workExperiences];
                            for (var i = 0; i < updatedList.length; i++) {
                              if (i == index) {
                                updatedList[i].isCurrentlyWorking = true;
                                updatedList[i].endDate =
                                    null; // Clear end date if currently working
                              } else {
                                updatedList[i].isCurrentlyWorking = false;
                              }
                            }
                            widget.onWorkExperiencesChanged(updatedList);
                          } else {
                            experience.isCurrentlyWorking = false;
                            _updateWorkExperience(index, experience);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 12),
                    // AI Enhancement Button
                    ElevatedButton.icon(
                      onPressed: () {
                        final controller = _getDescriptionController(
                          experience.id,
                          experience.description,
                        );
                        _showAIEnhancement(context, controller, () {
                          experience.description = controller.text;
                          _updateWorkExperience(index, experience);
                          setState(() {});
                        });
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Enhance with AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _getDescriptionController(
                        experience.id,
                        experience.description,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText:
                            'E.g., Have experience in Automation using Core Java, Selenium',
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        experience.description = value;
                        _updateWorkExperience(index, experience);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Dynamic Education Section Widget
class DynamicEducationSection extends StatefulWidget {
  final List<Education> educations;
  final Function(List<Education>) onEducationsChanged;
  final Color? accentColor;
  final bool atsFriendly;

  const DynamicEducationSection({
    super.key,
    required this.educations,
    required this.onEducationsChanged,
    this.accentColor,
    this.atsFriendly = false,
  });

  @override
  State<DynamicEducationSection> createState() =>
      _DynamicEducationSectionState();
}

class _DynamicEducationSectionState extends State<DynamicEducationSection> {
  bool _overlaps(DateTime? s1, DateTime? e1, DateTime? s2, DateTime? e2) {
    if (s1 == null || s2 == null) return false;
    final end1 = e1 ?? DateTime(9999, 12, 31);
    final end2 = e2 ?? DateTime(9999, 12, 31);
    int ym(DateTime d) => d.year * 12 + d.month;
    final s1m = ym(DateTime(s1.year, s1.month));
    final e1m = ym(DateTime(end1.year, end1.month));
    final s2m = ym(DateTime(s2.year, s2.month));
    final e2m = ym(DateTime(end2.year, end2.month));
    return s1m <= e2m && s2m <= e1m;
  }

  List<String> _findOverlaps() {
    final msgs = <String>[];
    final list = widget.educations;
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        if (_overlaps(
          list[i].startDate,
          list[i].endDate,
          list[j].startDate,
          list[j].endDate,
        )) {
          msgs.add('Education ${i + 1} overlaps with Education ${j + 1}');
        }
      }
    }
    return msgs;
  }

  void _addEducation() {
    final newEducation = Education(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final updatedList = [...widget.educations, newEducation];
    widget.onEducationsChanged(updatedList);
  }

  void _removeEducation(String id) {
    final updatedList = widget.educations.where((edu) => edu.id != id).toList();
    widget.onEducationsChanged(updatedList);
  }

  void _updateEducation(int index, Education education) {
    final updatedList = [...widget.educations];
    updatedList[index] = education;
    widget.onEducationsChanged(updatedList);
  }

  Future<void> _pickDate(
    BuildContext context,
    Function(DateTime?) onPicked, {
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.atsFriendly
        ? (widget.accentColor ?? Colors.black87)
        : (widget.accentColor ?? Colors.teal);
    final overlaps = _findOverlaps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.atsFriendly) ...[
              Icon(Icons.school, color: accentColor, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                'Education',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Education'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.atsFriendly
                    ? Colors.black87
                    : accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        if (overlaps.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overlapping education dates detected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...overlaps.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m, style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.educations.isEmpty)
          Card(
            elevation: widget.atsFriendly ? 0 : null,
            shape: widget.atsFriendly
                ? RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!widget.atsFriendly)
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'No education added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Education" to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...widget.educations.asMap().entries.map((entry) {
            final index = entry.key;
            final education = entry.value;

            return Card(
              elevation: widget.atsFriendly ? 0 : null,
              shape: widget.atsFriendly
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Education ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeEducation(education.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove this education',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: education.degree,
                            decoration: const InputDecoration(
                              labelText: 'Degree *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              education.degree = value;
                              _updateEducation(index, education);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: education.institution,
                            decoration: const InputDecoration(
                              labelText: 'College/University *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              education.institution = value;
                              _updateEducation(index, education);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: education.location,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              education.location = value;
                              _updateEducation(index, education);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: education.gpa,
                            decoration: const InputDecoration(
                              labelText: 'GPA (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              education.gpa = value;
                              _updateEducation(index, education);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(context, (date) {
                              setState(() {
                                education.startDate = date;
                                _updateEducation(index, education);
                              });
                            }, initial: education.startDate),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              education.startDate == null
                                  ? 'Start Date'
                                  : '${education.startDate!.month}/${education.startDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(context, (date) {
                              setState(() {
                                education.endDate = date;
                                _updateEducation(index, education);
                              });
                            }, initial: education.endDate),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              education.endDate == null
                                  ? 'End Date'
                                  : '${education.endDate!.month}/${education.endDate!.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: education.description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        education.description = value;
                        _updateEducation(index, education);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Dynamic Custom Fields Section Widget
class DynamicCustomFieldsSection extends StatefulWidget {
  final List<CustomField> customFields;
  final Function(List<CustomField>) onCustomFieldsChanged;
  final Color? accentColor;
  final bool atsFriendly;

  const DynamicCustomFieldsSection({
    super.key,
    required this.customFields,
    required this.onCustomFieldsChanged,
    this.accentColor,
    this.atsFriendly = false,
  });

  @override
  State<DynamicCustomFieldsSection> createState() =>
      _DynamicCustomFieldsSectionState();
}

class _DynamicCustomFieldsSectionState
    extends State<DynamicCustomFieldsSection> {
  void _addCustomField() {
    final newField = CustomField(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final updatedList = [...widget.customFields, newField];
    widget.onCustomFieldsChanged(updatedList);
  }

  void _removeCustomField(String id) {
    final updatedList = widget.customFields
        .where((field) => field.id != id)
        .toList();
    widget.onCustomFieldsChanged(updatedList);
  }

  void _updateCustomField(int index, CustomField field) {
    final updatedList = [...widget.customFields];
    updatedList[index] = field;
    widget.onCustomFieldsChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.atsFriendly
        ? (widget.accentColor ?? Colors.black87)
        : (widget.accentColor ?? Colors.blue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Custom Field button
        Row(
          children: [
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addCustomField,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Custom Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.atsFriendly
                    ? Colors.black87
                    : accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.customFields.isEmpty)
          Card(
            elevation: widget.atsFriendly ? 0 : null,
            shape: widget.atsFriendly
                ? RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!widget.atsFriendly)
                    Icon(
                      Icons.add_box_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'No custom fields added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Custom Field" to add additional sections',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...widget.customFields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;

            return Card(
              elevation: widget.atsFriendly ? 0 : null,
              shape: widget.atsFriendly
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Custom Field ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeCustomField(field.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove this field',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: field.label,
                      decoration: const InputDecoration(
                        labelText: 'Field Label *',
                        hintText: 'e.g., Volunteer Work, Publications, Awards',
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        field.label = value;
                        _updateCustomField(index, field);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: field.content,
                      decoration: const InputDecoration(
                        labelText: 'Content *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Enter the content for this custom section',
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        field.content = value;
                        _updateCustomField(index, field);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
