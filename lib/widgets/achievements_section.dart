import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class AchievementsSection extends StatefulWidget {
  final List<Achievement> achievements;
  final Function(List<Achievement>) onAchievementsChanged;

  const AchievementsSection({
    Key? key,
    required this.achievements,
    required this.onAchievementsChanged,
  }) : super(key: key);

  @override
  _AchievementsSectionState createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  void _addAchievement() {
    final newAchievement = Achievement(title: '');

    final updatedAchievements = List<Achievement>.from(widget.achievements)
      ..add(newAchievement);

    widget.onAchievementsChanged(updatedAchievements);
  }

  void _removeAchievement(int index) {
    final updatedAchievements = List<Achievement>.from(widget.achievements)
      ..removeAt(index);

    widget.onAchievementsChanged(updatedAchievements);
  }

  void _updateAchievement(int index, Achievement achievement) {
    final updatedAchievements = List<Achievement>.from(widget.achievements);
    updatedAchievements[index] = achievement;

    widget.onAchievementsChanged(updatedAchievements);
  }

  Future<DateTime?> _selectDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
  }

  String _getAchievementIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('award') || titleLower.contains('prize')) {
      return '🏆';
    } else if (titleLower.contains('certificate') ||
        titleLower.contains('certification')) {
      return '📜';
    } else if (titleLower.contains('recognition') ||
        titleLower.contains('honor')) {
      return '🎖️';
    } else if (titleLower.contains('scholarship')) {
      return '🎓';
    } else if (titleLower.contains('patent')) {
      return '💡';
    } else if (titleLower.contains('publication')) {
      return '📚';
    } else {
      return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (widget.achievements.isEmpty)
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
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No achievements added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Highlight your awards, recognitions, and notable accomplishments',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.achievements.asMap().entries.map((entry) {
          final index = entry.key;
          final achievement = entry.value;

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
                      // Achievement emoji
                      Text(
                        _getAchievementIcon(achievement.title),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          achievement.title.isEmpty
                              ? 'New Achievement ${index + 1}'
                              : achievement.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeAchievement(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Achievement Title
                  TextFormField(
                    initialValue: achievement.title,
                    decoration: const InputDecoration(
                      labelText: 'Achievement Title *',
                      hintText: 'e.g., Employee of the Year Award',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateAchievement(
                        index,
                        achievement.copyWith(title: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    initialValue: achievement.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'Describe the achievement and its significance...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _updateAchievement(
                        index,
                        achievement.copyWith(description: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date
                  InkWell(
                    onTap: () async {
                      final date = await _selectDate(context, achievement.date);
                      if (date != null) {
                        _updateAchievement(
                          index,
                          achievement.copyWith(date: date),
                        );
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date (Optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        achievement.date != null
                            ? '${achievement.date!.day}/${achievement.date!.month}/${achievement.date!.year}'
                            : 'Select date',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 16),

        // Add Achievement Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addAchievement,
            icon: const Icon(Icons.add),
            label: const Text('Add Achievement'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Achievement Templates
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Achievement Templates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick add common achievement types:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      [
                        {
                          'title': 'Employee of the Month',
                          'description':
                              'Recognized for outstanding performance and dedication',
                        },
                        {
                          'title': 'Project Excellence Award',
                          'description':
                              'Awarded for exceptional project delivery and leadership',
                        },
                        {
                          'title': 'Innovation Award',
                          'description':
                              'Recognized for innovative solutions and creative thinking',
                        },
                        {
                          'title': 'Team Leadership Recognition',
                          'description':
                              'Acknowledged for effective team management and mentoring',
                        },
                        {
                          'title': 'Customer Service Excellence',
                          'description':
                              'Recognized for exceptional customer satisfaction scores',
                        },
                        {
                          'title': 'Sales Achievement Award',
                          'description':
                              'Exceeded sales targets and achieved record performance',
                        },
                      ].map((template) {
                        final alreadyAdded = widget.achievements.any(
                          (a) => a.title == template['title'],
                        );
                        return ActionChip(
                          label: Text(
                            template['title']!,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: alreadyAdded
                              ? null
                              : () {
                                  final newAchievement = Achievement(
                                    title: template['title']!,
                                    description: template['description']!,
                                    date: DateTime.now(),
                                  );
                                  final updatedAchievements =
                                      List<Achievement>.from(
                                        widget.achievements,
                                      )..add(newAchievement);
                                  widget.onAchievementsChanged(
                                    updatedAchievements,
                                  );
                                },
                          backgroundColor: alreadyAdded
                              ? Colors.grey.shade200
                              : Colors.indigo.shade50,
                          labelStyle: TextStyle(
                            color: alreadyAdded
                                ? Colors.grey.shade500
                                : Colors.indigo,
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
