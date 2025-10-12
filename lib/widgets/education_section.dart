import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class EducationSection extends StatefulWidget {
  final List<Education> educations;
  final Function(List<Education>) onEducationsChanged;

  const EducationSection({
    super.key,
    required this.educations,
    required this.onEducationsChanged,
  });

  @override
  _EducationSectionState createState() => _EducationSectionState();
}

class _EducationSectionState extends State<EducationSection> {
  void _addEducation() {
    const newEducation = Education(degree: '', institution: '');

    final updatedEducations = List<Education>.from(widget.educations)
      ..add(newEducation);

    widget.onEducationsChanged(updatedEducations);
  }

  void _removeEducation(int index) {
    final updatedEducations = List<Education>.from(widget.educations)
      ..removeAt(index);

    widget.onEducationsChanged(updatedEducations);
  }

  void _updateEducation(int index, Education education) {
    final updatedEducations = List<Education>.from(widget.educations);
    updatedEducations[index] = education;

    widget.onEducationsChanged(updatedEducations);
  }

  Future<DateTime?> _selectDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (widget.educations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No education added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your educational background and qualifications',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.educations.asMap().entries.map((entry) {
          final index = entry.key;
          final education = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with delete button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          education.degree.isEmpty
                              ? 'New Education ${index + 1}'
                              : education.degree,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeEducation(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Degree
                  TextFormField(
                    initialValue: education.degree,
                    decoration: const InputDecoration(
                      labelText: 'Degree / Qualification *',
                      hintText: 'e.g., Bachelor of Computer Science',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateEducation(
                        index,
                        education.copyWith(degree: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Institution
                  TextFormField(
                    initialValue: education.institution,
                    decoration: const InputDecoration(
                      labelText: 'Institution / University *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateEducation(
                        index,
                        education.copyWith(institution: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Location
                  TextFormField(
                    initialValue: education.location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateEducation(
                        index,
                        education.copyWith(location: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // GPA (Optional)
                  TextFormField(
                    initialValue: education.gpa,
                    decoration: const InputDecoration(
                      labelText: 'GPA / Grade (Optional)',
                      hintText: 'e.g., 3.8/4.0 or First Class',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateEducation(index, education.copyWith(gpa: value));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await _selectDate(
                              context,
                              education.startDate,
                            );
                            if (date != null) {
                              _updateEducation(
                                index,
                                education.copyWith(startDate: date),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              education.startDate != null
                                  ? '${education.startDate!.month}/${education.startDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await _selectDate(
                              context,
                              education.endDate,
                            );
                            if (date != null) {
                              _updateEducation(
                                index,
                                education.copyWith(endDate: date),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              education.endDate != null
                                  ? '${education.endDate!.month}/${education.endDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    initialValue: education.description,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText:
                          'Notable achievements, coursework, thesis, etc.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _updateEducation(
                        index,
                        education.copyWith(description: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Add Education Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addEducation,
            icon: const Icon(Icons.add),
            label: const Text('Add Education'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
