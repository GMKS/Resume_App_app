import 'package:flutter/material.dart';

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

  WorkExperience({
    required this.id,
    this.jobTitle = '',
    this.company = '',
    this.location = '',
    this.startDate,
    this.endDate,
    this.description = '',
    this.achievements = const [],
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
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.atsFriendly) ...[
              Icon(Icons.work, color: accentColor, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                'Work Experience',
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
                            onPressed: () => _pickDate(context, (date) {
                              setState(() {
                                experience.endDate = date;
                                _updateWorkExperience(index, experience);
                              });
                            }, initial: experience.endDate),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              experience.endDate == null
                                  ? 'End Date'
                                  : '${experience.endDate!.month}/${experience.endDate!.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: experience.description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
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
                              labelText: 'University *',
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
