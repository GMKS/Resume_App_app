import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class SkillsSection extends StatefulWidget {
  final List<Skill> skills;
  final Function(List<Skill>) onSkillsChanged;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onSkillsChanged,
  });

  @override
  _SkillsSectionState createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final TextEditingController _skillController = TextEditingController();
  String _selectedCategory = 'Technical';

  final List<String> _categories = [
    'Technical',
    'Programming',
    'Software',
    'Design',
    'Languages',
    'Communication',
    'Management',
    'Other',
  ];

  void _addSkill() {
    if (_skillController.text.trim().isEmpty) return;

    final newSkill = Skill(
      name: _skillController.text.trim(),
      category: _selectedCategory,
      proficiency: 0.7, // Default proficiency
    );

    final updatedSkills = List<Skill>.from(widget.skills)..add(newSkill);
    widget.onSkillsChanged(updatedSkills);

    _skillController.clear();
  }

  void _removeSkill(int index) {
    final updatedSkills = List<Skill>.from(widget.skills)..removeAt(index);
    widget.onSkillsChanged(updatedSkills);
  }

  void _updateSkill(int index, Skill skill) {
    final updatedSkills = List<Skill>.from(widget.skills);
    updatedSkills[index] = skill;
    widget.onSkillsChanged(updatedSkills);
  }

  Map<String, List<Skill>> get _skillsByCategory {
    final Map<String, List<Skill>> grouped = {};
    for (final skill in widget.skills) {
      grouped.putIfAbsent(skill.category, () => []).add(skill);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Add Skill Section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Add New Skill',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add your professional skills, technical expertise, or competencies',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          labelText: 'Skill Name *',
                          hintText:
                              'Enter skill (e.g., Flutter, Python, Leadership)',
                          helperText:
                              'Type the name of your skill or expertise',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.star_outline,
                            color: Colors.amber,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          underline: Container(),
                          hint: const Text('Category'),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Skills by Category
        if (widget.skills.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No skills added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your skills to highlight your expertise',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._skillsByCategory.entries.map((entry) {
            final category = entry.key;
            final categorySkills = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...categorySkills.asMap().entries.map((skillEntry) {
                      final skillIndex = widget.skills.indexOf(
                        skillEntry.value,
                      );
                      final skill = skillEntry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    skill.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeSkill(skillIndex),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            if (skill.proficiency != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Proficiency: ',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${(skill.proficiency! * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: skill.proficiency!,
                                      onChanged: (value) {
                                        _updateSkill(
                                          skillIndex,
                                          skill.copyWith(proficiency: value),
                                        );
                                      },
                                      activeColor: Colors.indigo,
                                      divisions: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        // Quick Add Popular Skills
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Add Popular Skills',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      [
                        'Communication',
                        'Leadership',
                        'Problem Solving',
                        'Team Work',
                        'Time Management',
                        'Critical Thinking',
                        'Adaptability',
                        'Creativity',
                      ].map((skill) {
                        final alreadyAdded = widget.skills.any(
                          (s) => s.name == skill,
                        );
                        return ActionChip(
                          label: Text(skill),
                          onPressed: alreadyAdded
                              ? null
                              : () {
                                  final newSkill = Skill(
                                    name: skill,
                                    category: 'Communication',
                                    proficiency: 0.8,
                                  );
                                  final updatedSkills = List<Skill>.from(
                                    widget.skills,
                                  )..add(newSkill);
                                  widget.onSkillsChanged(updatedSkills);
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

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }
}
