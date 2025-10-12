import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class ExperienceSection extends StatefulWidget {
  final List<Experience> experiences;
  final Function(List<Experience>) onExperiencesChanged;

  const ExperienceSection({
    super.key,
    required this.experiences,
    required this.onExperiencesChanged,
  });

  @override
  _ExperienceSectionState createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection> {
  void _addExperience() {
    const newExperience = Experience(jobTitle: '', companyName: '');

    final updatedExperiences = List<Experience>.from(widget.experiences)
      ..add(newExperience);

    widget.onExperiencesChanged(updatedExperiences);
  }

  void _removeExperience(int index) {
    final updatedExperiences = List<Experience>.from(widget.experiences)
      ..removeAt(index);

    widget.onExperiencesChanged(updatedExperiences);
  }

  void _updateExperience(int index, Experience experience) {
    final updatedExperiences = List<Experience>.from(widget.experiences);

    // If this experience is being marked as current job,
    // unmark all other experiences as current job
    if (experience.isCurrentJob) {
      for (int i = 0; i < updatedExperiences.length; i++) {
        if (i != index && updatedExperiences[i].isCurrentJob) {
          updatedExperiences[i] = updatedExperiences[i].copyWith(
            isCurrentJob: false,
            // Keep their end date if they had one, otherwise set a default end date
            endDate: updatedExperiences[i].endDate ?? DateTime.now(),
          );
        }
      }
    }

    updatedExperiences[index] = experience;

    widget.onExperiencesChanged(updatedExperiences);
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

        if (widget.experiences.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.work_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No work experience added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your work experience to showcase your professional background',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.experiences.asMap().entries.map((entry) {
          final index = entry.key;
          final experience = entry.value;

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
                          experience.jobTitle.isEmpty
                              ? 'New Experience ${index + 1}'
                              : experience.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeExperience(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Job Title
                  TextFormField(
                    initialValue: experience.jobTitle,
                    decoration: const InputDecoration(
                      labelText: 'Job Title *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateExperience(
                        index,
                        experience.copyWith(jobTitle: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Company Name
                  TextFormField(
                    initialValue: experience.companyName,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateExperience(
                        index,
                        experience.copyWith(companyName: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Location
                  TextFormField(
                    initialValue: experience.location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateExperience(
                        index,
                        experience.copyWith(location: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Current Job Checkbox
                  CheckboxListTile(
                    title: const Text('This is my current job'),
                    value: experience.isCurrentJob,
                    onChanged: (value) {
                      _updateExperience(
                        index,
                        experience.copyWith(
                          isCurrentJob: value ?? false,
                          endDate: (value ?? false) ? null : experience.endDate,
                        ),
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
                              experience.startDate,
                            );
                            if (date != null) {
                              _updateExperience(
                                index,
                                experience.copyWith(startDate: date),
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
                              experience.startDate != null
                                  ? '${experience.startDate!.month}/${experience.startDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: experience.isCurrentJob
                              ? null
                              : () async {
                                  final date = await _selectDate(
                                    context,
                                    experience.endDate,
                                  );
                                  if (date != null) {
                                    _updateExperience(
                                      index,
                                      experience.copyWith(endDate: date),
                                    );
                                  }
                                },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: const OutlineInputBorder(),
                              suffixIcon: experience.isCurrentJob
                                  ? null
                                  : const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              experience.isCurrentJob
                                  ? 'Present'
                                  : experience.endDate != null
                                  ? '${experience.endDate!.month}/${experience.endDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Job Description
                  TextFormField(
                    initialValue: experience.description,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      hintText:
                          'Describe your key responsibilities, achievements, and impact...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    onChanged: (value) {
                      _updateExperience(
                        index,
                        experience.copyWith(description: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Add Experience Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add),
            label: const Text('Add Work Experience'),
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
